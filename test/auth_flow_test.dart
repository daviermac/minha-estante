import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_estante/app.dart';
import 'package:minha_estante/data/auth_repository.dart';
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

void main() {
  testWidgets(
      'Livro cadastrado aparece na lista e nos detalhes; logout limpa os dados',
      (tester) async {
    final repo = TestAuthRepository()
      ..session = const AuthSession('u1', 'teste@exemplo.com');
    addTearDown(repo.changes.close);
    await tester.pumpWidget(MinhaEstanteApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Dom Casmurro');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'Machado de Assis');
    await tester.enterText(find.byType(TextFormField).at(2), 'Romance');
    await tester
        .ensureVisible(find.byType(DropdownButtonFormField<StatusLeitura>));
    await tester.tap(find.byType(DropdownButtonFormField<StatusLeitura>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lendo').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4 estrelas').last);
    await tester.pumpAndSettle();
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
    await tester.pumpWidget(MinhaEstanteApp(repository: repo));
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
    await tester.pumpWidget(MinhaEstanteApp(repository: repo));
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
    await tester.pumpWidget(MinhaEstanteApp(repository: repo));
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
    await tester.pumpWidget(MinhaEstanteApp(repository: repo));
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
    await tester.pumpWidget(MinhaEstanteApp(repository: repo));
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
    await tester.pumpWidget(MinhaEstanteApp(repository: repo));
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
}
