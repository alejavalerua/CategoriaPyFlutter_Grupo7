import '../../domain/models/auth_user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/remote/i_authentication_source.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthenticationSource _dataSource;

  // Inyección de dependencias estricta
  AuthRepositoryImpl(this._dataSource);

  @override
  Future<AuthUser> signIn(String email, String password) async {
    final response = await _dataSource.login(email, password);
    
    // Aquí idealmente guardarías el response['accessToken'] usando GetStorage
    
    return AuthUser(
      id: "roble_auth", // Roble maneja sesión por token, mapeamos un ID genérico
      email: email,
      role: "student",
    );
  }

  @override
  Future<AuthUser> signUp(String email, String password, String name) async {
    final response = await _dataSource.signUp(email, password, name);
    return AuthUser(
      id: "roble_auth",
      email: email,
      role: "student",
    );
  }
}