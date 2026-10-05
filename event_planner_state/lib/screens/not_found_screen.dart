import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

/// Écran d'erreur générique (route inconnue ou identifiant d'événement
/// invalide). Réemploi du TP 3 ; la navigation n'est pas évaluée dans ce TP.
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
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
