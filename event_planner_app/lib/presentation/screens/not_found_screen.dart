import 'package:flutter/material.dart';

import '../routes.dart';
import '../widgets/state_views.dart';

/// Route inconnue ou arguments invalides : un écran explicite avec une issue,
/// plutôt qu'une erreur.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page introuvable')),
      body: EmptyView(
        icon: Icons.explore_off_outlined,
        title: 'Cette page n’existe pas',
        message: routeName == null ? null : 'Route demandée : $routeName',
        actionLabel: 'Revenir au catalogue',
        onAction: () =>
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
      ),
    );
  }
}
