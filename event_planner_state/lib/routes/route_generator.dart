import 'package:flutter/material.dart';

import '../data/event_repository.dart';
import '../models/event.dart';
import '../screens/callback_demo_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/home_shell_screen.dart';
import '../screens/not_found_screen.dart';
import 'app_routes.dart';

/// Fabrique des routes (réemploi TP 3, non évaluée dans ce TP).
abstract final class RouteGenerator {
  const RouteGenerator._();

  static const EventRepository _repository = EventRepository();

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _page(settings, const HomeShellScreen());

      case AppRoutes.callbackDemo:
        return _page(settings, const CallbackDemoScreen());

      case AppRoutes.eventDetail:
        final args = settings.arguments;
        if (args is! String) {
          return _page(
            settings,
            const NotFoundScreen(
              title: 'Argument manquant',
              message: 'La route de détail attend un identifiant (String).',
            ),
          );
        }
        final Event? event = _repository.findById(args);
        if (event == null) {
          return _page(
            settings,
            NotFoundScreen(
              title: 'Événement introuvable',
              message: 'Aucun événement pour l\'identifiant « $args ».',
            ),
          );
        }
        return _page(settings, EventDetailScreen(event: event));

      default:
        return null;
    }
  }

  static Route<dynamic> unknownRoute(RouteSettings settings) => _page(
        settings,
        NotFoundScreen(
          title: 'Page introuvable (404)',
          message: 'La route « ${settings.name} » n\'existe pas.',
        ),
      );

  static MaterialPageRoute<void> _page(RouteSettings settings, Widget child) =>
      MaterialPageRoute<void>(settings: settings, builder: (_) => child);
}
