import 'package:flutter/material.dart';

import 'screens/catalog_screen.dart';

/// Table de routes nommées — **unique point d'enregistrement** de la
/// navigation. Aucun écran ne construit de `MaterialPageRoute` lui-même.
abstract final class AppRoutes {
  static const String catalog = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case catalog:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const CatalogScreen(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page introuvable')),
          ),
        );
    }
  }
}
