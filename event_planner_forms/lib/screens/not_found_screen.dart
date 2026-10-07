import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

/// Écran d'erreur **unique** (TP 3), utilisé à la fois pour :
/// - la route inconnue (`onUnknownRoute`, erreur 404 générique) ;
/// - les trois cas d'erreur d'argument de la route de détail (argument absent,
///   type inattendu, identifiant inexistant) ;
/// - un argument de route de confirmation du mauvais type.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Erreur de navigation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: const Text('Retour à l\'accueil'),
                // rootNavigator: true pour sortir d'un éventuel Navigator
                // imbriqué d'onglet (TP 3, Partie D) : on ne sait pas dans
                // quel état est la pile locale, on reconstruit donc toute
                // la coquille depuis le Navigator racine.
                onPressed: () => Navigator.of(context, rootNavigator: true)
                    .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
