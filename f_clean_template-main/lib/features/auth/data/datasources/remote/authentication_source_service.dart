import 'dart:convert';
import 'package:http/http.dart' as http;
import 'i_authentication_source.dart';

class AuthenticationSourceService implements IAuthenticationSource {
  final http.Client httpClient;
  final String baseUrl = 'https://roble-api.openlab.uninorte.edu.co/auth/peer_sync_2e18809588';

  AuthenticationSourceService({http.Client? client})
    : httpClient = client ?? http.Client();

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await httpClient.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body); // Retorna accessToken y refreshToken
    } else {
      throw Exception('Error en Login: ${response.body}');
    }
  }

  @override
  Future<Map<String, dynamic>> signUp(String email, String password, String name) async {
    final response = await httpClient.post(
      Uri.parse('$baseUrl/signup-direct'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error en SignUp: ${response.body}');
    }
  }
}