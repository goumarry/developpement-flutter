import 'package:event_planner_app/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Enveloppe minimale d'un widget testé : le thème de l'application (les
/// widgets lisent son extension de couleurs) et un `Scaffold`.
Widget testApp(Widget child, {bool scaffold = true}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: scaffold ? Scaffold(body: child) : child,
  );
}
