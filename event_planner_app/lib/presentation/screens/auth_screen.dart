import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/rules/validators.dart';
import '../../state/auth_state.dart';
import '../utils/breakpoints.dart';

enum _AuthMode {
  signIn('Connexion', 'Se connecter'),
  register('Inscription', 'Créer mon compte'),
  reset('Mot de passe oublié', 'Envoyer le lien');

  const _AuthMode(this.title, this.submitLabel);
  final String title;
  final String submitLabel;
}

/// Connexion, création de compte et réinitialisation du mot de passe.
/// Renvoie `true` à l'écran appelant quand l'utilisateur est connecté : c'est
/// ce qui permet à l'action interrompue (s'inscrire, créer) de reprendre.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  void _switchTo(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _error = null;
      _info = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final auth = context.read<AuthState>();
    final email = _email.text.trim();
    final result = switch (_mode) {
      _AuthMode.signIn => await auth.signIn(
        email: email,
        password: _password.text,
      ),
      _AuthMode.register => await auth.register(
        email: email,
        password: _password.text,
      ),
      _AuthMode.reset => await auth.sendPasswordReset(email),
    };
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() {
        _busy = false;
        _error = result.error;
      });
      return;
    }
    if (_mode == _AuthMode.reset) {
      setState(() {
        _busy = false;
        _mode = _AuthMode.signIn;
        // Formulation volontairement conditionnelle : le service n'indique
        // pas si l'adresse correspond à un compte.
        _info =
            'Si un compte existe pour $email, un lien de '
            'réinitialisation vient de lui être envoyé.';
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: Text(_mode.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Breakpoints.readableWidth,
              ),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_info != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _info!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        gap,
                      ],
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Courriel',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: compose([requiredField(), email()]),
                      ),
                      if (_mode != _AuthMode.reset) ...[
                        gap,
                        TextFormField(
                          controller: _password,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe',
                          ),
                          obscureText: true,
                          textInputAction: _mode == _AuthMode.register
                              ? TextInputAction.next
                              : TextInputAction.done,
                          autofillHints: [
                            _mode == _AuthMode.register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          onFieldSubmitted: _mode == _AuthMode.signIn
                              ? (_) => _submit()
                              : null,
                          validator: compose([
                            requiredField(),
                            if (_mode == _AuthMode.register) minLength(6),
                          ]),
                        ),
                      ],
                      if (_mode == _AuthMode.register) ...[
                        gap,
                        TextFormField(
                          controller: _passwordConfirmation,
                          decoration: const InputDecoration(
                            labelText: 'Confirmation du mot de passe',
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          // Validation croisée avec le champ mot de passe.
                          validator: (value) => value == _password.text
                              ? null
                              : 'Les deux mots de passe ne correspondent pas.',
                        ),
                      ],
                      if (_error != null) ...[
                        gap,
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_mode.submitLabel),
                      ),
                      const SizedBox(height: 8),
                      for (final mode in _AuthMode.values)
                        if (mode != _mode)
                          TextButton(
                            onPressed: _busy ? null : () => _switchTo(mode),
                            child: Text(mode.title),
                          ),
                    ],
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
