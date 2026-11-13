import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'data/auth_repository.dart';
import 'data/livro_repository.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<(AuthRepository, LivroRepository)> _initialization =
      _initialize();

  Future<(AuthRepository, LivroRepository)> _initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    // Opcional: --dart-define=USE_FIREBASE_EMULATOR=true para testes locais
    // com o Firebase Local Emulator Suite (Auth 9099, Firestore 8085).
    if (const bool.fromEnvironment('USE_FIREBASE_EMULATOR') ||
        const bool.fromEnvironment('USE_AUTH_EMULATOR')) {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8085);
    }
    await FirebaseAuth.instance.setLanguageCode('pt-BR');
    return (
      FirebaseAuthRepository(FirebaseAuth.instance),
      FirestoreLivroRepository(FirebaseFirestore.instance),
    );
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<(AuthRepository, LivroRepository)>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final (auth, livros) = snapshot.data!;
            return MinhaEstanteApp(repository: auth, livros: livros);
          }
          return MaterialApp(
            title: 'Minha Estante',
            debugShowCheckedModeBanner: false,
            theme: estanteTheme(),
            home: Scaffold(
              body: Center(
                child: snapshot.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text(
                              'Não foi possível iniciar o aplicativo. Verifique a conexão e tente novamente. Se o problema continuar, contate o responsável pelo aplicativo.',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                              onPressed: () => setState(
                                  () => _initialization = _initialize()),
                              child: const Text('Tentar novamente')),
                        ]),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          );
        },
      );
}
