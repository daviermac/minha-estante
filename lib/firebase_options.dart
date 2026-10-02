import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Substitua este arquivo com `flutterfire configure` para o projeto real.
// Alternativamente, configure os identificadores web por --dart-define-from-file.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
    if (!kIsWeb ||
        apiKey.isEmpty ||
        appId.isEmpty ||
        senderId.isEmpty ||
        projectId.isEmpty) {
      throw StateError('Execute flutterfire configure antes de iniciar.');
    }
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      authDomain: authDomain,
    );
  }
}
