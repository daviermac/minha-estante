import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_estante/app.dart';
import 'package:minha_estante/data/auth_repository.dart';
import 'package:minha_estante/data/livro_repository.dart';
import 'package:minha_estante/domain/livro.dart';
import 'package:minha_estante/ui/auth/auth_controller.dart';

// Somente para testes: a aplicação real sempre usa FirebaseAuthRepository.
class TestAuthRepository implements AuthRepository {
  final changes = StreamController<AuthSession?>.broadcast();
  AuthSession? session;
  int loginCalls = 0;
  int registerCalls = 0;
  int resetCalls = 0;
  Completer<void>? pending;
  AuthFailure? failure;

  @override
  Stream<AuthSession?> authStateChanges() async* {
    yield session;
    yield* changes.stream;
  }

  void emit(AuthSession? value) {
    session = value;
    changes.add(value);
  }

  @override
  Future<void> login(String email, String password) async {
    loginCalls++;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
    emit(AuthSession('test-user', email));
  }

  @override
  Future<void> register(String email, String password) async {
    registerCalls++;
    if (failure != null) throw failure!;
    emit(AuthSession('new-user', email));
  }

  @override
  Future<void> resetPassword(String email) async {
    resetCalls++;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> logout() async => emit(null);
}

// Somente para testes: guarda livros por UID, como users/{uid}/books.
class TestLivroRepository implements LivroRepository {
  final _dados = <String, List<Livro>>{};
  final _changes = StreamController<String>.broadcast();
  var _seq = 0;
  LivroFailure? failure;
  Completer<void>? pending;

  List<Livro> of(String uid) => _dados[uid] ?? const [];

  @override
  Stream<List<Livro>> watch(String uid) async* {
    if (failure != null) throw failure!;
    yield of(uid);
    yield* _changes.stream.where((u) => u == uid).map((_) => of(uid));
  }

  Future<void> _write(String uid, List<Livro> Function(List<Livro>) f) async {
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
    _dados[uid] = f(of(uid));
    _changes.add(uid);
  }

  @override
  Future<void> create(String uid, Livro livro) =>
      _write(uid, (l) => [livro.copyWith(id: 'b${++_seq}'), ...l]);

  @override
  Future<void> update(String uid, Livro livro) =>
      _write(uid, (l) => [for (final x in l) x.id == livro.id ? livro : x]);

  @override
  Future<void> delete(String uid, String id) =>
      _write(uid, (l) => l.where((x) => x.id != id).toList());
}

late TestLivroRepository livros;

Widget app(AuthRepository repo) =>
    MinhaEstanteApp(repository: repo, livros: livros);

Future<void> preencherLivro(WidgetTester tester, String titulo,
    {String status = 'Lendo', String nota = '4 estrelas'}) async {
  await tester.enterText(find.byType(TextFormField).at(0), titulo);
  await tester.enterText(find.byType(TextFormField).at(1), 'Machado de Assis');
  await tester.enterText(find.byType(TextFormField).at(2), 'Romance');
  await tester
      .ensureVisible(find.byType(DropdownButtonFormField<StatusLeitura>));
  await tester.tap(find.byType(DropdownButtonFormField<StatusLeitura>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(status).last);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
  await tester.tap(find.byType(DropdownButtonFormField<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(nota).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => livros = TestLivroRepository());

  testWidgets(
      'Livro cadastrado aparece na lista e nos detalhes; outra conta não o vê',
      (tester) async {
    final repo = TestAuthRepository()
      ..session = const AuthSession('u1', 'teste@exemplo.com');
    addTearDown(repo.changes.close);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await preencherLivro(tester, 'Dom Casmurro');
    await tester.ensureVisible(find.text('Salvar livro'));
    await tester.tap(find.text('Salvar livro'));
    await tester.pumpAndSettle();
    expect(find.text('Dom Casmurro'), findsOneWidget);
    await tester.tap(find.text('Dom Casmurro'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes do livro'), findsOneWidget);
    expect(find.text('Romance'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    repo.emit(const AuthSession('u2', 'outro@exemplo.com'));
    await tester.pumpAndSettle();
    expect(find.text('Sua estante está vazia'), findsOneWidget);
    expect(find.text('Dom Casmurro'), findsNothing);
  });
  test('Valida e-mail, senha e traduz erros frequentes', () {
    expect(validateEmail(''), isNotNull);
    expect(validateEmail('nome@'), isNotNull);
    expect(validateEmail(' nome@exemplo.com '), isNull);
    expect(validatePassword('12345'), isNotNull);
    expect(validatePassword('123456'), isNull);
    expect(messageForAuthCode('invalid-credential'), contains('Confira'));
    expect(messageForAuthCode('network-request-failed'), contains('internet'));
    expect(messageForAuthCode('email-already-in-use'),
        contains('já está cadastrado'));
  });

  testWidgets('Formulário inválido não chama autenticação', (tester) async {
    final repo = TestAuthRepository();
    addTearDown(repo.changes.close);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(repo.loginCalls, 0);
  });

  testWidgets('Loading bloqueia duplicação; erro permite nova tentativa',
      (tester) async {
    final repo = TestAuthRepository()
      ..pending = Completer<void>()
      ..failure = const AuthFailure('Confira seu e-mail e senha.');
    addTearDown(repo.changes.close);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).at(0), 'teste@exemplo.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repo.loginCalls, 1);
    repo.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Confira seu e-mail e senha.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
  });

  testWidgets('Cadastro exige confirmação e abre área interna', (tester) async {
    final repo = TestAuthRepository();
    addTearDown(repo.changes.close);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não tenho conta. Criar conta'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).at(0), 'novo@exemplo.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.enterText(find.byType(TextFormField).at(2), '654321');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text('As senhas não coincidem.'), findsOneWidget);
    expect(repo.registerCalls, 0);
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Sua biblioteca pessoal'), findsOneWidget);
    expect(find.text('novo@exemplo.com'), findsOneWidget);
  });

  testWidgets('Recuperação mostra confirmação e volta ao login',
      (tester) async {
    final repo = TestAuthRepository();
    addTearDown(repo.changes.close);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'teste@exemplo.com');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(repo.resetCalls, 1);
    expect(find.textContaining('Solicitação processada.'), findsOneWidget);
    await tester.tap(find.text('Voltar ao login'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('Sessão existente abre estante; sair retorna ao login',
      (tester) async {
    final repo = TestAuthRepository()
      ..session = const AuthSession('u1', 'teste@exemplo.com');
    addTearDown(repo.changes.close);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('Sua biblioteca pessoal'), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
    expect(find.text('Sua biblioteca pessoal'), findsNothing);
  });

  testWidgets('Perder sessão destrói cadastro de livro aberto', (tester) async {
    final repo = TestAuthRepository()
      ..session = const AuthSession('u1', 'teste@exemplo.com');
    addTearDown(repo.changes.close);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Novo livro'), findsOneWidget);
    repo.emit(null);
    await tester.pumpAndSettle();
    expect(find.text('Novo livro'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
    repo.emit(const AuthSession('u2', 'outro@exemplo.com'));
    await tester.pumpAndSettle();
    expect(find.text('Sua estante está vazia'), findsOneWidget);
    expect(find.text('Novo livro'), findsNothing);
  });

  testWidgets('CRUD: cria, edita, cancela e confirma exclusão', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = TestAuthRepository()
      ..session = const AuthSession('u1', 'a@exemplo.com');
    addTearDown(repo.changes.close);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('Sua estante está vazia'), findsOneWidget);
    // CREATE
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await preencherLivro(tester, 'Memórias Póstumas');
    await tester.ensureVisible(find.text('Salvar livro'));
    await tester.tap(find.text('Salvar livro'));
    await tester.pumpAndSettle();
    expect(livros.of('u1').single.titulo, 'Memórias Póstumas');
    expect(find.textContaining('1 livro cadastrado'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // fecha o SnackBar
    await tester.pumpAndSettle();
    // UPDATE
    await tester.tap(find.text('Memórias Póstumas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Machado de Assis'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Quincas Borba');
    await tester.ensureVisible(find.text('Salvar alterações'));
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();
    expect(livros.of('u1').single.titulo, 'Quincas Borba');
    expect(find.text('Quincas Borba'), findsWidgets);
    // DELETE cancelado
    await tester.tap(find.byTooltip('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir livro?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(livros.of('u1'), hasLength(1));
    // DELETE confirmado
    await tester.tap(find.byTooltip('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(livros.of('u1'), isEmpty);
    expect(find.text('Sua estante está vazia'), findsOneWidget);
  });

  testWidgets('Salvar mostra loading, bloqueia duplicação e trata erro',
      (tester) async {
    final repo = TestAuthRepository()
      ..session = const AuthSession('u1', 'a@exemplo.com');
    addTearDown(repo.changes.close);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await preencherLivro(tester, 'Iracema');
    livros
      ..pending = Completer<void>()
      ..failure = const LivroFailure('Sem conexão com o servidor.');
    await tester.ensureVisible(find.text('Salvar livro'));
    await tester.tap(find.text('Salvar livro'));
    await tester.pump();
    expect(find.text('Salvando…'), findsOneWidget);
    livros.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Sem conexão com o servidor.'), findsOneWidget);
    expect(find.text('Salvar livro'), findsOneWidget);
    expect(livros.of('u1'), isEmpty);
  });

  testWidgets('Falha ao carregar mostra erro e permite tentar novamente',
      (tester) async {
    final repo = TestAuthRepository()
      ..session = const AuthSession('u1', 'a@exemplo.com');
    addTearDown(repo.changes.close);
    livros.failure = const LivroFailure('Você não tem permissão.');
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('Você não tem permissão.'), findsOneWidget);
    livros.failure = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Sua estante está vazia'), findsOneWidget);
  });

  testWidgets('Busca e filtro de status restringem a lista', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await livros.create(
        'u1',
        const Livro(
            titulo: 'Dom Casmurro',
            autor: 'Machado de Assis',
            genero: 'Romance',
            status: StatusLeitura.concluido,
            nota: 5));
    await livros.create(
        'u1',
        const Livro(
            titulo: 'Iracema',
            autor: 'José de Alencar',
            genero: 'Romance',
            status: StatusLeitura.queroLer,
            nota: 3));
    final repo = TestAuthRepository()
      ..session = const AuthSession('u1', 'a@exemplo.com');
    addTearDown(repo.changes.close);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 livros cadastrados · 1 concluído'),
        findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Concluído'));
    await tester.pumpAndSettle();
    expect(find.text('Dom Casmurro'), findsOneWidget);
    expect(find.text('Iracema'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
    await tester.enterText(find.byType(TextField).first, 'alencar');
    await tester.pumpAndSettle();
    expect(find.text('Iracema'), findsOneWidget);
    expect(find.text('Dom Casmurro'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Nenhum livro encontrado com esses filtros.'),
        findsOneWidget);
  });

  test('Livro converte para o documento do Firestore', () {
    const livro = Livro(
        titulo: 'A',
        autor: 'B',
        genero: 'C',
        status: StatusLeitura.concluido,
        nota: 5);
    final map = livro.toMap();
    expect(map, {
      'title': 'A',
      'author': 'B',
      'genre': 'C',
      'status': 'concluido',
      'rating': 5
    });
    final lido = Livro.fromMap('id1', map);
    expect(lido.id, 'id1');
    expect(lido.status, StatusLeitura.concluido);
    expect(messageForFirestoreCode('permission-denied'), contains('permissão'));
  });
}
