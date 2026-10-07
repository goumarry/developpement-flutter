import 'package:flutter/material.dart';

import '../domain/models/event.dart';
import 'screens/auth_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/event_editor_screen.dart';
import 'screens/home_shell_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/registration_screen.dart';

/// Arguments de [AppRoutes.eventDetail].
///
/// [preview] permet d'afficher l'événement sans attendre (on vient d'une
/// liste qui le possède déjà). Sans lui, l'écran charge l'événement du
/// catalogue à partir de [eventId].
class EventDetailArgs {
  const EventDetailArgs({required this.eventId, this.preview});

  EventDetailArgs.of(Event event) : this(eventId: event.id, preview: event);

  final String eventId;
  final Event? preview;
}

/// Table de routes nommées — **unique point d'enregistrement** de la
/// navigation. Aucun écran ne construit de `MaterialPageRoute` lui-même : il
/// appelle `Navigator.pushNamed` avec une de ces constantes.
///
/// | Route            | Argument            | Valeur de retour                 |
/// |------------------|---------------------|----------------------------------|
/// | [home]           | —                   | —                                |
/// | [eventDetail]    | [EventDetailArgs]   | —                                |
/// | [registration]   | [Event]             | `bool` : ajouté au panier        |
/// | [auth]           | —                   | `bool` : connecté                |
/// | [eventEditor]    | [Event]? (null = création) | `String` : message de succès |
///
/// Les arguments sont **validés ici** : un argument absent ou du mauvais type
/// mène à [NotFoundScreen], jamais à une erreur de transtypage dans un écran.
abstract final class AppRoutes {
  static const String home = '/';
  static const String eventDetail = '/event';
  static const String registration = '/event/register';
  static const String auth = '/auth';
  static const String eventEditor = '/organizer/edit';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const HomeShellScreen(),
        );
      case eventDetail:
        if (args is! EventDetailArgs) return _notFound(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => EventDetailScreen(args: args),
        );
      case registration:
        if (args is! Event) return _notFound(settings);
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => RegistrationScreen(event: args),
        );
      case auth:
        return MaterialPageRoute<bool>(
          settings: settings,
          fullscreenDialog: true,
          builder: (_) => const AuthScreen(),
        );
      case eventEditor:
        if (args != null && args is! Event) return _notFound(settings);
        return MaterialPageRoute<String>(
          settings: settings,
          fullscreenDialog: true,
          builder: (_) => EventEditorScreen(event: args as Event?),
        );
      default:
        return _notFound(settings);
    }
  }

  static Route<void> _notFound(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => NotFoundScreen(routeName: settings.name),
    );
  }
}
