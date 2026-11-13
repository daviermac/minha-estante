import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/auth_repository.dart';
import '../../data/livro_repository.dart';
import '../../domain/livro.dart';
import '../auth/auth_controller.dart';
import 'library_screens.dart';

/// Estado da lista vinda do Firestore.
class EstanteEstado {
  const EstanteEstado.carregando()
      : livros = null,
        erro = null;
  const EstanteEstado.dados(List<Livro> this.livros) : erro = null;
  const EstanteEstado.falha(String this.erro) : livros = null;
  final List<Livro>? livros;
  final String? erro;
}

class LibraryArea extends StatefulWidget {
  const LibraryArea({
    super.key,
    required this.repository,
    required this.livros,
    required this.session,
  });
  final AuthRepository repository;
  final LivroRepository livros;
  final AuthSession session;
  @override
  State<LibraryArea> createState() => _LibraryAreaState();
}

class _LibraryAreaState extends State<LibraryArea> {
  final _estado =
      ValueNotifier<EstanteEstado>(const EstanteEstado.carregando());
  final _navigator = GlobalKey<NavigatorState>();
  late final _auth = AuthController(widget.repository);
  StreamSubscription<List<Livro>>? _sub;

  String get _uid => widget.session.uid;

  @override
  void initState() {
    super.initState();
    _escutar();
  }

  /// READ em tempo real: snapshots() atualiza a lista após cada alteração.
  void _escutar() {
    _sub?.cancel();
    _estado.value = const EstanteEstado.carregando();
    _sub = widget.livros.watch(_uid).listen(
          (livros) => _estado.value = EstanteEstado.dados(livros),
          onError: (Object error) => _estado.value = EstanteEstado.falha(
              error is LivroFailure
                  ? error.message
                  : 'Não foi possível carregar seus livros.'),
        );
  }

  void _avisar(String mensagem) {
    final context = _navigator.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  /// CREATE
  Future<void> _cadastrar() async {
    final salvo = await _navigator.currentState!.push<bool>(
      MaterialPageRoute(
        builder: (_) => FormularioLivroTela(
          onSalvar: (livro) => widget.livros.create(_uid, livro),
        ),
      ),
    );
    if (salvo == true && mounted) _avisar('Livro cadastrado na sua estante.');
  }

  /// UPDATE
  Future<void> _editar(Livro livro) async {
    final salvo = await _navigator.currentState!.push<bool>(
      MaterialPageRoute(
        builder: (_) => FormularioLivroTela(
          livro: livro,
          onSalvar: (editado) =>
              widget.livros.update(_uid, editado.copyWith(id: livro.id)),
        ),
      ),
    );
    if (salvo == true && mounted) _avisar('Alterações salvas.');
  }

  /// DELETE (a confirmação acontece na tela de detalhes)
  Future<void> _excluir(Livro livro) async {
    await widget.livros.delete(_uid, livro.id!);
    if (!mounted) return;
    _navigator.currentState!.popUntil((route) => route.isFirst);
    _avisar('“${livro.titulo}” foi excluído.');
  }

  void _abrir(Livro livro) {
    _navigator.currentState!.push(
      MaterialPageRoute(
        builder: (_) => ValueListenableBuilder<EstanteEstado>(
          valueListenable: _estado,
          builder: (context, estado, _) {
            // Mostra sempre a versão mais recente do documento.
            final atual =
                estado.livros?.where((l) => l.id == livro.id).firstOrNull ??
                    livro;
            return DetalhesLivroTela(
              livro: atual,
              onEditar: () => _editar(atual),
              onExcluir: () => _excluir(atual),
            );
          },
        ),
      ),
    );
  }

  Future<void> _sair() async {
    final success = await _auth.logout();
    if (!mounted || success) return;
    _avisar(_auth.error ?? 'Não foi possível sair. Tente novamente.');
  }

  @override
  void dispose() {
    _sub?.cancel();
    _estado.dispose();
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
              listenable: Listenable.merge([_estado, _auth]),
              builder: (context, _) => EstanteTela(
                livros: _estado.value.livros,
                erro: _estado.value.erro,
                email: widget.session.email,
                onAdicionar: _cadastrar,
                onAbrirLivro: _abrir,
                onTentarNovamente: _escutar,
                onSair: _sair,
                saindo: _auth.busy,
              ),
            ),
          ),
        ),
      );
}
