import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'i_groups_remote_source.dart';


class GroupsRemoteSource implements IGroupsRemoteSource {
  final http.Client httpClient;
  final String dbUrl =
      'https://roble-api.openlab.uninorte.edu.co/database/peer_sync_2e18809588';

  GroupsRemoteSource({http.Client? client})
    : httpClient = client ?? http.Client();

  // Función auxiliar para peticiones GET (Leer)
  Future<List<dynamic>> _readTable(
    String tableName,
    String query,
    Map<String, String> headers,
  ) async {
    final res = await httpClient.get(
      Uri.parse('$dbUrl/read?tableName=$tableName&$query'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data is List ? data : (data['data'] ?? data['records'] ?? []);
    }
    return [];
  }

  // Función auxiliar para peticiones POST (Insertar)
  Future<void> _insertTable(
    String tableName,
    List<Map<String, dynamic>> records,
    Map<String, String> headers,
  ) async {
    final res = await httpClient.post(
      Uri.parse('$dbUrl/insert'),
      headers: headers,
      body: jsonEncode({'tableName': tableName, 'records': records}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Error al insertar en $tableName: ${res.body}');
    }
  }

  @override
  Future<void> importGroupsFromCsv(String courseId, String csvString) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenA');
    if (token == null) throw Exception('No hay sesión activa.');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // 1. Convertir el texto CSV a una lista de filas
    final converter = CsvDecoder();
    List<List<dynamic>> rowsAsListOfValues = converter.convert(csvString);

    if (rowsAsListOfValues.length <= 1)
      throw Exception('El archivo CSV está vacío o no tiene datos válidos.');

    // 2. Mapear dinámicamente las columnas según el encabezado
    final header = rowsAsListOfValues[0]
        .map((e) => e.toString().trim())
        .toList();
    final colCatName = header.indexOf('Group Category Name');
    final colGroupName = header.indexOf('Group Name');
    final colFirstName = header.indexOf('First Name');
    final colLastName = header.indexOf('Last Name');
    final colEmail = header.indexOf('Email Address');

    if (colCatName == -1 || colGroupName == -1 || colEmail == -1) {
      throw Exception('El CSV no tiene las columnas requeridas.');
    }

    // Mapas para almacenar los IDs autogenerados por ROBLE en memoria
    Map<String, String> categoryIds = {};
    Map<String, String> groupIds = {};

    // Iteramos fila por fila (saltando el encabezado)
    for (int i = 1; i < rowsAsListOfValues.length; i++) {
      final row = rowsAsListOfValues[i];
      if (row.length < header.length) continue;

      final catName = row[colCatName].toString().trim();
      final groupName = row[colGroupName].toString().trim();
      final firstName = row[colFirstName].toString().trim();
      final lastName = row[colLastName].toString().trim();
      final email = row[colEmail].toString().trim();

      if (catName.isEmpty || groupName.isEmpty || email.isEmpty) continue;

      // ==========================================
      // FASE A: GESTIÓN DE LA CATEGORÍA
      // ==========================================
      if (!categoryIds.containsKey(catName)) {
        // ¿Existe en la BD?
        var existingCat = await _readTable(
          'Category',
          'course_id=$courseId&category_name=$catName',
          headers,
        );
        if (existingCat.isEmpty) {
          // Si no existe, la creamos
          await _insertTable('Category', [
            {'course_id': courseId, 'category_name': catName},
          ], headers);
          // La volvemos a leer para obtener el _id que ROBLE le asignó
          existingCat = await _readTable(
            'Category',
            'course_id=$courseId&category_name=$catName',
            headers,
          );
        }
        categoryIds[catName] = existingCat.first['_id'];
      }
      final currentCatId = categoryIds[catName]!;

      // ==========================================
      // FASE B: GESTIÓN DEL GRUPO
      // ==========================================
      final groupKey = '$currentCatId-$groupName'; // Llave única en memoria
      if (!groupIds.containsKey(groupKey)) {
        var existingGroup = await _readTable(
          'Group',
          'category_id=$currentCatId&group_name=$groupName',
          headers,
        );
        if (existingGroup.isEmpty) {
          await _insertTable('Group', [
            {'category_id': currentCatId, 'group_name': groupName},
          ], headers);
          existingGroup = await _readTable(
            'Group',
            'category_id=$currentCatId&group_name=$groupName',
            headers,
          );
        }
        groupIds[groupKey] = existingGroup.first['_id'];
      }
      final currentGroupId = groupIds[groupKey]!;

      // ==========================================
      // FASE C: GESTIÓN DEL MIEMBRO (Estudiante)
      // ==========================================
      // Verificamos si el estudiante ya está en ESTE grupo específico
      var existingMember = await _readTable(
        'GroupMember',
        'group_id=$currentGroupId&email=$email',
        headers,
      );
      if (existingMember.isEmpty) {
        // Lo insertamos en la tabla GroupMember de ROBLE
        await _insertTable('GroupMember', [
          {
            'group_id': currentGroupId,
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
          },
        ], headers);
      }
    }
  }
}
