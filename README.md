# Minha Estante

Aplicativo Flutter para organizar uma biblioteca pessoal. Esta entrega implementa as três telas descritas no trabalho:

1. **Minha Estante:** lista título, autor e status de leitura de cada livro; tocar em um item abre os detalhes.
2. **Cadastrar livro:** formulário com título, autor, gênero, status e nota de 1 a 5; todos os campos são obrigatórios e mostram mensagens de validação.
3. **Detalhes do livro:** mostra todas as informações do livro selecionado.

Após o cadastro, o app volta à listagem e mostra uma confirmação. Os livros são mantidos **em memória** enquanto o aplicativo está aberto, conforme o escopo da primeira etapa. Ao fechar o app, a lista volta a ficar vazia.

## Como executar

Requer Flutter com Dart 3 ou superior e um emulador ou dispositivo configurado. Na pasta deste projeto, execute:

```sh
flutter create --project-name minha_estante .
flutter pub get
flutter run
```

O comando `flutter create` gera as pastas de plataforma (`android/`, `ios/` etc.) que não estão incluídas neste pacote. O código do aplicativo está em `lib/main.dart` e não usa bibliotecas externas.

## Fluxo de conferência

1. Abra o app e confira o estado vazio da tela inicial.
2. Toque em **Cadastrar livro** e tente salvar sem preencher: cada campo obrigatório deve indicar o erro.
3. Preencha título, autor, gênero, status e nota; toque em **Salvar livro**.
4. Confira o livro na listagem e a mensagem de confirmação.
5. Toque no livro e confira as informações completas na tela de detalhes.
