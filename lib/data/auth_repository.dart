import 'package:firebase_auth/firebase_auth.dart';

class AuthSession {
  const AuthSession(this.uid, this.email);
  final String uid;
  final String email;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

abstract class AuthRepository {
  Stream<AuthSession?> authStateChanges();
  Future<void> login(String email, String password);
  Future<void> register(String email, String password);
  Future<void> resetPassword(String email);
  Future<void> logout();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

  @override
  Stream<AuthSession?> authStateChanges() => _auth.authStateChanges().map(
        (user) => user == null ? null : AuthSession(user.uid, user.email ?? ''),
      );

  Future<void> _execute(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(messageForAuthCode(error.code));
    } catch (_) {
      throw const AuthFailure('Não foi possível concluir. Tente novamente.');
    }
  }

  @override
  Future<void> login(String email, String password) => _execute(() async {
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
      });

  @override
  Future<void> register(String email, String password) => _execute(() async {
        await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
      });

  @override
  Future<void> resetPassword(String email) => _execute(() async {
        try {
          await _auth.sendPasswordResetEmail(email: email);
        } on FirebaseAuthException catch (error) {
          // Mesma resposta para contas existentes e inexistentes.
          if (error.code != 'user-not-found') rethrow;
        }
      });

  @override
  Future<void> logout() => _execute(_auth.signOut);
}

String messageForAuthCode(String code) => switch (code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' =>
        'Não foi possível entrar. Confira seu e-mail e senha e tente novamente.',
      'email-already-in-use' =>
        'Este e-mail já está cadastrado. Entre ou recupere sua senha.',
      'invalid-email' => 'Informe um endereço de e-mail válido.',
      'weak-password' ||
      'password-does-not-meet-requirements' =>
        'A senha não atende aos requisitos. Use uma senha mais forte.',
      'network-request-failed' =>
        'Sem conexão. Verifique sua internet e tente novamente.',
      'too-many-requests' =>
        'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
      'user-disabled' =>
        'Esta conta está desativada. Entre em contato com o responsável pelo aplicativo.',
      'operation-not-allowed' =>
        'O acesso por e-mail está indisponível no momento.',
      _ => 'Não foi possível concluir. Tente novamente.',
    };
