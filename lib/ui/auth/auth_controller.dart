import 'package:flutter/foundation.dart';
import '../../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.repository);
  final AuthRepository repository;
  bool busy = false;
  String? error;
  bool _disposed = false;

  Future<bool> run(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthFailure catch (failure) {
      error = failure.message;
      return false;
    } catch (_) {
      error = 'Não foi possível concluir. Tente novamente.';
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> login(String email, String password) =>
      run(() => repository.login(email.trim(), password));
  Future<bool> register(String email, String password) =>
      run(() => repository.register(email.trim(), password));
  Future<bool> resetPassword(String email) =>
      run(() => repository.resetPassword(email.trim()));
  Future<bool> logout() => run(repository.logout);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Informe seu e-mail.';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
    return 'Informe um e-mail válido, como nome@exemplo.com.';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Informe sua senha.';
  if (value.length < 6) return 'A senha precisa ter pelo menos 6 caracteres.';
  return null;
}
