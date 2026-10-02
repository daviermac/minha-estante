# Minha Estante — Trabalho 2

**Aluno:** Davi Renato dos Santos Paixão Moreira.  
**Tema:** biblioteca pessoal e acompanhamento de leituras.  
**Tecnologias:** Flutter, Dart e Firebase Authentication.

**Repositório público:** https://github.com/daviermac/minha-estante

Evolução do mesmo aplicativo do Trabalho 1. Foram preservados o modelo Livro, o tema e as telas de listagem, cadastro de livro e detalhes. A nova camada de autenticação fica antes da biblioteca.

## Funcionalidades

- Cadastro, login e recuperação de senha por e-mail pelo Firebase Authentication.
- Confirmação de senha, validação de e-mail e senha mínima de 6 caracteres. Políticas adicionais do projeto Firebase também são respeitadas pelo servidor.
- Indicador de carregamento e bloqueio de envios duplicados durante operações.
- Erros de credenciais, conta existente, rede e limites de tentativas traduzidos para português.
- Estado da sessão acompanhado por `authStateChanges()`, inclusive sessão restaurada pelo SDK.
- Botão **Sair** no canto superior direito da tela Minha Estante.
- Ao perder a sessão, toda a navegação interna é removida. O usuário seguinte começa com sua própria lista vazia.
- Cadastro e consulta de livros em memória, com validação e confirmação, como no Trabalho 1.

As senhas são enviadas ao Firebase pelo SDK. Não são gravadas em arquivos, banco próprio, logs ou estado global. Os campos do formulário são limpos após sucesso e descartados ao sair da tela.

## Estado da configuração

**A conexão com o projeto Firebase do aluno ainda precisa ser configurada.** O código usa o SDK real; não há login de demonstração no aplicativo. Sem os identificadores do projeto, a inicialização não libera acesso à biblioteca.

Este repositório foi criado na etapa do Trabalho 2. O primeiro commit importa exatamente o código da entrega anterior, preservado no pacote original do Trabalho 1; os commits seguintes registram a evolução para autenticação. As capturas finais ainda precisam ser adicionadas após a conexão real ao Firebase.

## Configurar e executar

Código compilado com Flutter 3.47.6 e Dart 3.13.5. As pastas de plataforma web e Android estão incluídas. Na pasta que contém este README:

```sh
flutter pub get
```

Caso ainda faltem as pastas `web/` e `android/`, gere-as uma vez:

```sh
flutter create --empty --platforms=web,android --project-name minha_estante .
```

1. Abra o [Firebase Console](https://console.firebase.google.com/) e crie ou selecione o projeto Minha Estante.
2. Em **Authentication → Método de login**, habilite **E-mail/senha** e salve.
3. Instale as ferramentas oficiais e conecte a conta:

```sh
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Escolha o seu projeto e as plataformas web e/ou Android. O comando substitui `lib/firebase_options.dart` com os identificadores reais. Não use chaves de conta de serviço no app.

```sh
flutter run -d chrome
```

Para testar no Android, use um aparelho/emulador configurado e execute `flutter run`. O projeto Firebase precisa ter a configuração da plataforma Android gerada pelo FlutterFire.

### Alternativa de configuração somente web

Cadastre um app web no Firebase Console. Copie `firebase-config.example.json` para `firebase-config.local.json` e preencha as cinco propriedades com `apiKey`, `appId`, `messagingSenderId`, `projectId` e `authDomain` da configuração web. Depois:

```sh
flutter run -d chrome --dart-define-from-file=firebase-config.local.json
```

Se o provedor exigir domínio autorizado, confira o domínio de teste em **Authentication → Configurações → Domínios autorizados**. Use somente o domínio em que vai executar o app.

## Organização

```text
lib/
  main.dart                       inicialização do Firebase e erro de abertura
  app.dart                        tema e proteção pelo estado da sessão
  firebase_options.dart           configuração por plataforma
  data/auth_repository.dart       chamadas ao Firebase e tradução de erros
  domain/livro.dart                modelo do Trabalho 1
  ui/auth/auth_controller.dart    operação assíncrona, loading e validações
  ui/auth/auth_screen.dart        login, cadastro e recuperação
  ui/library/library_area.dart    navegação interna e livros da sessão
  ui/library/library_screens.dart telas preservadas do Trabalho 1
test/auth_flow_test.dart          testes locais com repositório de teste
```

## Verificação

```sh
dart format lib test
flutter analyze
flutter test
```

Os testes usam uma implementação isolada de `AuthRepository` para verificar interface e navegação. Eles não comprovam a configuração do serviço Firebase. A conferência real deve incluir criar uma conta, sair, entrar novamente, recarregar com sessão ativa e solicitar um e-mail de recuperação.

Verificação local em 02/10/2026: `dart format` executado, 8 testes aprovados e `flutter build web` concluído. `flutter analyze` foi tentado, mas o analisador não conseguiu criar seu diretório de estado `.dartServer` por uma restrição de acesso do ambiente; portanto, não há resultado de análise estática concluída. A compilação Android e a autenticação contra um projeto Firebase real ainda não foram verificadas.

## Capturas e entrega

Após conectar o Firebase e testar, adicione capturas reais de:

1. Login.
2. Cadastro de conta.
3. Recuperação de senha com a confirmação da solicitação.
4. Minha Estante autenticada, com o botão **Sair** visível.

Inclua no PDF final essas capturas, seu nome, nome do aplicativo, tema, explicação do fluxo e link clicável do mesmo repositório do Trabalho 1. As capturas não foram incluídas antecipadamente para não apresentar fluxos simulados como autenticação real.

## Limitações e Trabalho 3

Os livros ainda não são persistidos: fechar o app, recarregar a página ou sair da conta limpa a lista. O estado de autenticação é gerenciado e persistido pelo Firebase. A próxima evolução prevista é Cloud Firestore com dados vinculados ao UID do usuário e CRUD completo.

Referências: [configuração FlutterFire](https://firebase.google.com/docs/flutter/setup), [autenticação por e-mail/senha](https://firebase.google.com/docs/auth/flutter/password-auth).
