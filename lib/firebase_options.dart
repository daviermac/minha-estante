import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Configuração do projeto Firebase "minha-estante-daviermac".
///
/// Estes identificadores são públicos (ficam no código de qualquer app web);
/// quem protege os dados são o Firebase Authentication e as Security Rules.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
        'Esta versão está configurada para Web. Rode com: flutter run -d chrome');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCKLvpWbgkvxDrI0wTBC8U6PCHX4dBceB4',
    appId: '1:1071189844113:web:d38d79fafb5f0958c69f30',
    messagingSenderId: '1071189844113',
    projectId: 'minha-estante-daviermac',
    authDomain: 'minha-estante-daviermac.firebaseapp.com',
    storageBucket: 'minha-estante-daviermac.firebasestorage.app',
  );
}
