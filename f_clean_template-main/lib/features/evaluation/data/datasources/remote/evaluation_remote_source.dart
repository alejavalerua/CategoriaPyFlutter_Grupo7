import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'i_evaluation_remote_source.dart';

class EvaluationRemoteSource implements IEvaluationRemoteSource {
  final http.Client httpClient;
  final String dbUrl = 'https://roble-api.openlab.uninorte.edu.co/database/peer_sync_2e18809588';

  EvaluationRemoteSource({http.Client? client}) : httpClient = client ?? http.Client();

  Future<List<dynamic>> _readTable(
    String tableName,
    Map<String, String> queryParams,
    Map<String, String> headers,
  ) async {
    // Esto asegura que los espacios y caracteres especiales se codifiquen a %20 etc.
    final uri = Uri.parse(
      '$dbUrl/read',
    ).replace(queryParameters: {'tableName': tableName, ...queryParams});

    final res = await httpClient.get(uri, headers: headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data is List ? data : (data['data'] ?? data['records'] ?? []);
    } else {
  
      return [];
    }
  }

  // 2. REFACTORIZADO: Agregamos impresiones para saber exactamente dónde falla
  Future<void> _insertTable(
    String tableName,
    List<Map<String, dynamic>> records,
    Map<String, String> headers,
  ) async {
    final bodyStr = jsonEncode({'tableName': tableName, 'records': records});

    final res = await httpClient.post(
      Uri.parse('$dbUrl/insert'),
      headers: headers,
      body: bodyStr,
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      
      throw Exception('Error al insertar en $tableName: ${res.body}');
    } else {
      print('respuesta exitosa al insertar en $tableName: ${res.body}');
    }
  }

  @override
  Future<void> createActivity(String categoryId, String name, String description, DateTime startDate, DateTime endDate, bool visibility) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenA');
    if (token == null) throw Exception('No hay sesión activa.');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Convertimos las fechas a UTC ISO-8601 para que PostgreSQL no se queje
    final startIso = startDate.toUtc().toIso8601String();
    final endIso = endDate.toUtc().toIso8601String();

    final res = await httpClient.post(
      Uri.parse('$dbUrl/insert'),
      headers: headers,
      body: jsonEncode({
        'tableName': 'Activity',
        'records': [
          {
            // No mandamos _id para que ROBLE lo genere automáticamente
            'category_id': categoryId,
            'name': name,
            'description': description.isEmpty ? null : description, // Manejo de Nulos
            'start_date': startIso,
            'end_date': endIso,
            'visibility': visibility,
          }
        ]
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Error al crear la actividad: ${res.body}');
    }
  }

  @override
  Future<List<dynamic>> getActivitiesByCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenA');
    if (token == null) throw Exception('No hay sesión activa.');

    final uri = Uri.parse('$dbUrl/read').replace(queryParameters: {
      'tableName': 'Activity',
      'category_id': categoryId,
    });

    final res = await httpClient.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data is List ? data : (data['data'] ?? data['records'] ?? []);
    } else {
      throw Exception('Error al obtener actividades: ${res.body}');
    }
  }

  @override
  Future<List<dynamic>> getPeers(String categoryId, String studentEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenA');
    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

    // 1. Buscar todos los grupos de esta categoría
    final groups = await _readTable('Group', {'category_id': categoryId}, headers);
    String? myGroupId;
    // 2. Buscar en qué grupo está el estudiante actual
    for (var g in groups) {
      final members = await _readTable('GroupMember', {'group_id': g['_id'], 'email': studentEmail}, headers);
      if (members.isNotEmpty) {
        myGroupId = g['_id'];
        break;
      }
    }
    
    if (myGroupId == null) throw Exception('No tienes un grupo asignado en esta categoría.');

    // 3. Traer a todos los miembros de ese grupo y excluir al estudiante actual
    final allMembers = await _readTable('GroupMember', {'group_id': myGroupId}, headers);
    return allMembers; 
  }

  @override
  Future<List<dynamic>> getCriteria(String activityId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenA');
    return await _readTable('Criteria', {}, {
      'Content-Type': 'application/json', 
      'Authorization': 'Bearer $token'
    });
  }

  // NUEVO MÉTODO: Trae las evaluaciones que ya le hice a mis compañeros en esta actividad
  Future<Map<String, Map<String, double>>> getMyEvaluations(String activityId, String myEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenA');
    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

    // 1. Buscamos las cabeceras (Evaluations) hechas por mí
    final evals = await _readTable('Evaluation', {
      'activity_id': activityId,
      'evaluator_id': myEmail
    }, headers);

    Map<String, Map<String, double>> history = {};

    // 2. Para cada evaluación, buscamos el detalle de las notas
    for (var eval in evals) {
      final evalId = eval['_id'];
      final evaluatedEmail = eval['evaluated_id'];
      
      final details = await _readTable('ResultPerCriteria', {'evaluation_id': evalId}, headers);
      
      Map<String, double> scores = {};
      for (var d in details) {
        scores[d['criteria_id']] = double.tryParse(d['criteria_score'].toString()) ?? 0.0;
      }
      
      history[evaluatedEmail] = scores;
    }

    return history;
  }

  // MÉTODO ACTUALIZADO: Evita duplicados y divide entre 4
  @override
  Future<void> submitEvaluation(String activityId, String categoryId, String evaluatorEmail, String evaluatedEmail, String comments, Map<String, double> scores) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenA');
    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

    // === VALIDACIÓN DE DUPLICADOS ===
    final existingEval = await _readTable('Evaluation', {
      'activity_id': activityId,
      'evaluator_id': evaluatorEmail,
      'evaluated_id': evaluatedEmail
    }, headers);

    if (existingEval.isNotEmpty) {
      throw Exception('Ya calificaste a este compañero anteriormente.');
    }
    // ================================

    final groups = await _readTable('Group', {'category_id': categoryId}, headers);
    String? groupId;
    for (var g in groups) {
      final members = await _readTable('GroupMember', {'group_id': g['_id'], 'email': evaluatorEmail}, headers);
      if (members.isNotEmpty) { groupId = g['_id']; break; }
    }

    // === CÁLCULO EXACTO ENTRE 4 ===
    double total = 0;
    scores.values.forEach((v) => total += v);
    double generalScore = total / 4.0; // Dividimos explícitamente entre 4
    // ================================

    await _insertTable('Evaluation', [{
      'activity_id': activityId,
      'group_id': groupId,
      'evaluator_id': evaluatorEmail,
      'evaluated_id': evaluatedEmail,
      'comment': comments.isEmpty ? null : comments,
      'general_score': generalScore
    }], headers);

    final evals = await _readTable('Evaluation', {
      'activity_id': activityId,
      'evaluator_id': evaluatorEmail,
      'evaluated_id': evaluatedEmail
    }, headers);
    
    if (evals.isEmpty) throw Exception('Error de sincronización con la base de datos.');
    final evalId = evals.last['_id'];

    List<Map<String, dynamic>> details = [];
    scores.forEach((criteriaId, score) {
      details.add({
        'evaluation_id': evalId,
        'criteria_id': criteriaId,
        'criteria_score': score
      });
    });

    if (details.isNotEmpty) {
      await _insertTable('ResultPerCriteria', details, headers);
    }
  }

  // NUEVO MÉTODO: Trae el promedio de las calificaciones que me han puesto
  Future<Map<String, double>> getMyAverageResults(String activityId, String myEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenA');
    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

    // 1. Buscamos las evaluaciones donde YO soy el evaluado
    final evals = await _readTable('Evaluation', {
      'activity_id': activityId,
      'evaluated_id': myEmail
    }, headers);

    if (evals.isEmpty) return {}; // Si nadie me ha calificado, retorno vacío

    Map<String, List<double>> criteriaScores = {};
    List<double> generalScores = [];

    // 2. Extraemos las notas de todas las evaluaciones que me hicieron
    for (var eval in evals) {
      generalScores.add(double.tryParse(eval['general_score'].toString()) ?? 0.0);
      
      final details = await _readTable('ResultPerCriteria', {'evaluation_id': eval['_id']}, headers);
      for (var d in details) {
        String cId = d['criteria_id'];
        double val = double.tryParse(d['criteria_score'].toString()) ?? 0.0;
        criteriaScores.putIfAbsent(cId, () => []).add(val);
      }
    }

    // 3. Calculamos los promedios de cada criterio
    Map<String, double> averages = {};
    criteriaScores.forEach((cId, list) {
      double sum = list.fold(0.0, (a, b) => a + b);
      averages[cId] = sum / list.length;
    });

    // 4. Calculamos el promedio general
    double genSum = generalScores.fold(0.0, (a, b) => a + b);
    averages['general_score'] = genSum / generalScores.length;

    return averages;
  }

}