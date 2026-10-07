import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'widgets/state_views.dart';

/// Affichée à la place de l'application si l'initialisation (Firebase) échoue
/// au démarrage : un écran explicite avec « Réessayer », au lieu d'une
/// exception non interceptée avant le premier rendu.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Planner',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: ErrorView(
            message:
                'L’application n’a pas pu démarrer : la configuration '
                'Firebase est absente ou incomplète.',
            onRetry: onRetry,
          ),
        ),
      ),
    );
  }
}
