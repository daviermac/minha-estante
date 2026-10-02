import 'package:flutter/material.dart';
import '../../data/auth_repository.dart';
import 'auth_controller.dart';

enum AuthMode { login, register, reset }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.repository});
  final AuthRepository repository;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  var _form = GlobalKey<FormState>();
  late final _controller = AuthController(widget.repository);
  AuthMode _mode = AuthMode.login;
  bool _hidden = true;
  String? _success;

  void _changeMode(AuthMode mode) {
    if (_controller.busy) return;
    setState(() {
      _mode = mode;
      _form = GlobalKey<FormState>();
      _password.clear();
      _confirmation.clear();
      _hidden = true;
      _success = null;
      _controller.error = null;
    });
  }

  Future<void> _submit() async {
    if (_controller.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _success = null);
    final mode = _mode;
    final success = switch (mode) {
      AuthMode.login => await _controller.login(_email.text, _password.text),
      AuthMode.register =>
        await _controller.register(_email.text, _password.text),
      AuthMode.reset => await _controller.resetPassword(_email.text),
    };
    if (!mounted) return;
    if (success) {
      _password.clear();
      _confirmation.clear();
      if (mode == AuthMode.reset) {
        setState(() => _success =
            'Solicitação processada. Se houver uma conta com este e-mail, você receberá um link para redefinir a senha. Confira também o spam.');
      }
    }
    // Login e cadastro redirecionam pelo estado do Firebase, não por push manual.
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      AuthMode.login => 'Entrar',
      AuthMode.register => 'Criar conta',
      AuthMode.reset => 'Recuperar senha',
    };
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => PopScope(
        canPop: _mode == AuthMode.login && !_controller.busy,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_controller.busy) _changeMode(AuthMode.login);
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Minha Estante'),
            leading: _mode == AuthMode.login
                ? null
                : IconButton(
                    tooltip: 'Voltar ao login',
                    onPressed: _controller.busy
                        ? null
                        : () => _changeMode(AuthMode.login),
                    icon: const Icon(Icons.arrow_back),
                  ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _form,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.auto_stories_outlined,
                              size: 56, color: Color(0xFF148E8A)),
                          const SizedBox(height: 20),
                          Text(title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(switch (_mode) {
                            AuthMode.login =>
                              'Entre para acessar sua biblioteca pessoal.',
                            AuthMode.register =>
                              'Crie sua conta e organize suas leituras.',
                            AuthMode.reset =>
                              'Informe seu e-mail para receber o link de recuperação.',
                          }),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _email,
                            enabled: !_controller.busy,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            textInputAction: _mode == AuthMode.reset
                                ? TextInputAction.done
                                : TextInputAction.next,
                            decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: Icon(Icons.mail_outline)),
                            validator: validateEmail,
                            onFieldSubmitted: _mode == AuthMode.reset
                                ? (_) => _submit()
                                : null,
                          ),
                          if (_mode != AuthMode.reset) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _password,
                              enabled: !_controller.busy,
                              obscureText: _hidden,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: [
                                _mode == AuthMode.register
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password
                              ],
                              textInputAction: _mode == AuthMode.register
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                helperText: _mode == AuthMode.register
                                    ? 'Pelo menos 6 caracteres'
                                    : null,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _hidden
                                      ? 'Mostrar senha'
                                      : 'Ocultar senha',
                                  onPressed: _controller.busy
                                      ? null
                                      : () =>
                                          setState(() => _hidden = !_hidden),
                                  icon: Icon(_hidden
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                ),
                              ),
                              validator: validatePassword,
                              onFieldSubmitted: _mode == AuthMode.login
                                  ? (_) => _submit()
                                  : null,
                            ),
                          ],
                          if (_mode == AuthMode.register) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmation,
                              enabled: !_controller.busy,
                              obscureText: _hidden,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                  labelText: 'Confirmar senha',
                                  prefixIcon: Icon(Icons.lock_outline)),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Confirme sua senha.'
                                      : value != _password.text
                                          ? 'As senhas não coincidem.'
                                          : null,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ],
                          if (_controller.error != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                                liveRegion: true,
                                child: Text(_controller.error!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error))),
                          ],
                          if (_success != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                                liveRegion: true,
                                child: Text(_success!,
                                    style: const TextStyle(
                                        color: Color(0xFF17674E)))),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _controller.busy ? null : _submit,
                            style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52)),
                            child: _controller.busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Text(_mode == AuthMode.reset
                                    ? 'Enviar link de recuperação'
                                    : title),
                          ),
                          if (_mode == AuthMode.login) ...[
                            const SizedBox(height: 8),
                            TextButton(
                                onPressed: _controller.busy
                                    ? null
                                    : () => _changeMode(AuthMode.reset),
                                child: const Text('Esqueci minha senha')),
                            const Divider(),
                            TextButton(
                                onPressed: _controller.busy
                                    ? null
                                    : () => _changeMode(AuthMode.register),
                                child:
                                    const Text('Não tenho conta. Criar conta')),
                          ] else
                            TextButton(
                                onPressed: _controller.busy
                                    ? null
                                    : () => _changeMode(AuthMode.login),
                                child: const Text('Voltar ao login')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
