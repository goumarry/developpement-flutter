import 'package:flutter/material.dart';

import '../data/sample_events.dart';
import '../models/event.dart';
import '../models/formule.dart';
import '../screens/confirmation_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/main_shell_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/package_selection_screen.dart';
import 'app_routes.dart';

/// Arguments **typés** de la route de confirmation. Une classe dédiée plutôt
/// qu'une `Map` : le cast dans le générateur est alors sans ambiguïté et une
/// faute de frappe sur une clé devient une erreur de compilation.
class ConfirmationArgs {
  const ConfirmationArgs({required this.event, required this.formule});

  final Event event;
  final Formule formule;
}

/// Fabrique centralisée des routes de l'application.
///
/// Traite chaque route comme une **interface publique** : les arguments reçus
/// via [RouteSettings] sont validés explicitement, et tout écart (argument
/// absent, type inattendu, identifiant inexistant) mène à un écran d'erreur
/// lisible — jamais à une exception non interceptée ni à un écran blanc.
abstract final class RouteGenerator {
  const RouteGenerator._();

  /// `onGenerateRoute` de l'application (Navigator racine).
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    if (settings.name == AppRoutes.home) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const MainShellScreen(),
      );
    }
    // Routes du parcours (détail / sélection / confirmation).
    return parcoursRoute(settings);
  }

  /// Sous-ensemble du routage réutilisé tel quel par les [Navigator] imbriqués
  /// des onglets (Partie D). Renvoie `null` si `settings.name` n'est pas une
  /// route de parcours connue — le Navigator appelant bascule alors sur son
  /// `onUnknownRoute`.
  static Route<dynamic>? parcoursRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.eventDetail:
        return _eventDetailRoute(settings);

      case AppRoutes.packageSelection:
        final args = settings.arguments;
        // Argument optionnel mais, s'il est fourni, il doit être une String.
        final String eventTitle = args is String ? args : 'cet événement';
        return MaterialPageRoute<Formule>(
          settings: settings,
          builder: (_) => PackageSelectionScreen(eventTitle: eventTitle),
        );

      case AppRoutes.confirmation:
        final args = settings.arguments;
        if (args is! ConfirmationArgs) {
          return _errorRoute(
            settings,
            title: 'Récapitulatif indisponible',
            message:
                "L'écran de confirmation attend des arguments de type "
                'ConfirmationArgs (événement + formule). Reçu : '
                '${args.runtimeType}.',
          );
        }
        // Transition en fondu via PageRouteBuilder (aucune dépendance externe).
        return _fadeRoute(
          settings,
          ConfirmationScreen(event: args.event, formule: args.formule),
        );

      default:
        return null;
    }
  }

  /// `onUnknownRoute` : écran 404 générique pour n'importe quel nom de route
  /// non enregistré.
  static Route<dynamic> unknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => NotFoundScreen(
        title: 'Page introuvable (404)',
        message:
            'La route « ${settings.name ?? '(sans nom)'} » n\'existe pas dans '
            'cette application.',
      ),
    );
  }

  // --- Détail d'événement : les trois cas d'erreur d'argument -----------------

  static Route<dynamic> _eventDetailRoute(RouteSettings settings) {
    final Object? args = settings.arguments;

    // Cas 1 : argument absent.
    if (args == null) {
      return _errorRoute(
        settings,
        title: 'Aucun événement demandé',
        message:
            'La route de détail a été ouverte sans identifiant d\'événement '
            '(settings.arguments == null).',
      );
    }

    // Cas 2 : argument d'un type inattendu (on attend un String id).
    if (args is! String) {
      return _errorRoute(
        settings,
        title: 'Argument de route invalide',
        message:
            'La route de détail attend un identifiant texte (String). '
            'Type reçu : ${args.runtimeType}.',
      );
    }

    // Cas 3 : identifiant bien formé mais absent du jeu de données.
    final Event? event = findEventById(args);
    if (event == null) {
      return _errorRoute(
        settings,
        title: 'Événement introuvable',
        message: 'Aucun événement ne correspond à l\'identifiant « $args ».',
      );
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => EventDetailScreen(event: event),
    );
  }

  // --- Helpers ---------------------------------------------------------------

  static Route<dynamic> _errorRoute(
    RouteSettings settings, {
    required String title,
    required String message,
  }) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => NotFoundScreen(title: title, message: message),
    );
  }

  static Route<T> _fadeRoute<T>(RouteSettings settings, Widget child) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, widget) =>
          FadeTransition(opacity: animation, child: widget),
    );
  }
}
