import 'package:f_clean_template/features/auth/domain/models/authentication_user.dart';
import 'package:f_clean_template/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:get/get.dart';

import 'package:loggy/loggy.dart';

class AuthenticationController extends GetxController {
  final IAuthRepository repoAuthentication;
  final _logged = false.obs;
  final _isLoading = false.obs;

  AuthenticationController(this.repoAuthentication);

  bool get isLoading => _isLoading.value;
  bool get isLogged => _logged.value;

  Future<bool> login(String email, String password) async {
    logInfo('AuthenticationController: Login $email $password');
    if (!_validate(email, password)) {
      logWarning('AuthenticationController: Invalid email or password');
      return false;
    }
    _isLoading.value = true;
    var rta = await repoAuthentication.login(
      AuthenticationUser(email: email, name: email, password: password),
    );
    _logged.value = rta;
    _isLoading.value = false;
    return rta;
  }

  Future<bool> signUp(String email, String password) async {
    logInfo('AuthenticationController: Sign Up $email $password');
    if (!_validate(email, password)) {
      logWarning('AuthenticationController: Invalid email or password');
      return false;
    }
    _isLoading.value = true;
    await repoAuthentication.signUp(
      AuthenticationUser(email: email, name: email, password: password),
    );
    _isLoading.value = false;
    return true;
  }

  Future<void> logOut() async {
    logInfo('AuthenticationController: Log Out');
    await repoAuthentication.logOut();
    _logged.value = false;
  }

  bool _validate(String email, String password) =>
      email.isNotEmpty && password.length > 6;
}
