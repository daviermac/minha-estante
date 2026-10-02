import 'package:flutter/material.dart';
import '../../data/auth_repository.dart';
import '../../domain/livro.dart';
import '../auth/auth_controller.dart';
import 'library_screens.dart';

class LibraryArea extends StatefulWidget {
  const LibraryArea(
      {super.key, required this.repository, required this.session});
  final AuthRepository repository;
  final AuthSession session;
  @override
  State<LibraryArea> createState() => _LibraryAreaState();
}

class _LibraryAreaState extends State<LibraryArea> {
  final _livros = ValueNotifier<List<Livro>>([]);
  final _navigator = GlobalKey<NavigatorState>();
  late final _auth = AuthController(widget.repository);

  Future<void> _cadastrar(BuildContext context) async {
    final livro = await _navigator.currentState!.push<Livro>(
      MaterialPageRoute(builder: (_) => const CadastroLivroTela()),
    );
    if (!mounted || !context.mounted || livro == null) return;
    _livros.value = [..._livros.value, livro];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('“${livro.titulo}” foi cadastrado na sua estante.')),
    );
  }

  Future<void> _sair(BuildContext context) async {
    final success = await _auth.logout();
    if (!mounted || !context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_auth.error ?? 'Não foi possível sair. Tente novamente.')),
      );
    }
  }

  @override
  void dispose() {
    _livros.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NavigatorPopHandler(
        onPopWithResult: (_) => _navigator.currentState!.maybePop(),
        child: Navigator(
          key: _navigator,
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (context) => ListenableBuilder(
              listenable: Listenable.merge([_livros, _auth]),
              builder: (context, _) => EstanteTela(
                livros: _livros.value,
                email: widget.session.email,
                onAdicionar: () => _cadastrar(context),
                onAbrirLivro: (livro) => _navigator.currentState!.push(
                  MaterialPageRoute(
                      builder: (_) => DetalhesLivroTela(livro: livro)),
                ),
                onSair: () => _sair(context),
                saindo: _auth.busy,
              ),
            ),
          ),
        ),
      );
}
