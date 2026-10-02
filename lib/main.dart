import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'data/auth_repository.dart';
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
  late Future<AuthRepository> _initialization = _initialize();

  Future<AuthRepository> _initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    await FirebaseAuth.instance.setLanguageCode('pt-BR');
    return FirebaseAuthRepository(FirebaseAuth.instance);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AuthRepository>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return MinhaEstanteApp(repository: snapshot.data!);
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
