import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../routes.dart';

/// Garde des actions qui exigent une identité (s'inscrire, créer un
/// événement).
///
/// Déjà connecté : renvoie `true` immédiatement. Sinon, **propose**
/// explicitement la connexion — l'action n'échoue jamais en silence — puis
/// ouvre l'écran d'authentification et renvoie sa valeur de retour (`true`
/// si l'utilisateur s'est connecté).
Future<bool> ensureSignedIn(
  BuildContext context, {
  required String reason,
}) async {
  if (context.read<AuthState>().isSignedIn) return true;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.lock_outline),
      title: const Text('Connexion requise'),
      content: Text(reason),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Se connecter'),
        ),
      ],
    ),
  );
  if (accepted != true || !context.mounted) return false;
  final signedIn = await Navigator.of(context).pushNamed<bool>(AppRoutes.auth);
  return signedIn ?? false;
}

/// Message bref en bas d'écran, en remplaçant le précédent.
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
