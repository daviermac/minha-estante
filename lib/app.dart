import 'package:flutter/material.dart';
import 'data/auth_repository.dart';
import 'ui/auth/auth_screen.dart';
import 'ui/library/library_area.dart';

ThemeData estanteTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F7F2),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF148E8A)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B3040),
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );

class MinhaEstanteApp extends StatefulWidget {
  const MinhaEstanteApp({super.key, required this.repository});
  final AuthRepository repository;
  @override
  State<MinhaEstanteApp> createState() => _MinhaEstanteAppState();
}

class _MinhaEstanteAppState extends State<MinhaEstanteApp> {
  late final _sessionStream = widget.repository.authStateChanges();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Minha Estante',
        debugShowCheckedModeBanner: false,
        theme: estanteTheme(),
        // Todas as URLs entram pelo gate. Rotas privadas só existem dentro dele.
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _gate()),
        onGenerateInitialRoutes: (_) =>
            [MaterialPageRoute(builder: (_) => _gate())],
      );

  Widget _gate() => StreamBuilder<AuthSession?>(
        stream: _sessionStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Scaffold(
                body: Center(
                    child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                  'Não foi possível verificar sua sessão. Feche e abra o aplicativo para tentar novamente.'),
            )));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final session = snapshot.data;
          if (session == null) return AuthScreen(repository: widget.repository);
          // Trocar a sessão destrói toda a pilha privada e os dados em memória.
          return LibraryArea(
            key: ValueKey(session.uid),
            repository: widget.repository,
            session: session,
          );
        },
      );
}
