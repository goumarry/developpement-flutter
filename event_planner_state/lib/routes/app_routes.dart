import 'route_generator.dart';

/// Noms de route (réemploi du TP 3, non évalué ici mais nécessaire pour montrer
/// l'état partagé entre écrans). Fabrication des routes : [RouteGenerator].
abstract final class AppRoutes {
  const AppRoutes._();

  /// Liste des événements. Aucun argument.
  static const String home = '/';

  /// Détail d'un événement + ses sessions. Argument : `String id`.
  static const String eventDetail = '/event-detail';

  /// Démonstration de la Partie A (recompositions callback vs Provider).
  static const String callbackDemo = '/demo-recompositions';
}
