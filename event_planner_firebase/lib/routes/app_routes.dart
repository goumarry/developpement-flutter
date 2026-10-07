import 'route_generator.dart';

/// Noms de route de l'application, sous forme de **constantes typées**
/// (TP 3). Fabrication effective des routes : [RouteGenerator].
abstract final class AppRoutes {
  const AppRoutes._();

  /// Coquille principale à onglets (TP 3 Partie D + TP 4 + TP 5 fusionnés).
  static const String home = '/';

  /// Détail d'un événement + ses sessions. Argument : `String id`.
  static const String eventDetail = '/event-detail';

  /// Sélection d'une formule (TP 3). Argument : `String` (titre de
  /// l'événement). Valeur de retour : `Formule?`.
  static const String packageSelection = '/package-selection';

  /// Récapitulatif de réservation (TP 3). Argument : `ConfirmationArgs`.
  static const String confirmation = '/confirmation';

  /// Démonstration de la Partie A du TP 4 (recompositions callback vs Provider).
  static const String callbackDemo = '/demo-recompositions';

  /// Nom volontairement **non enregistré**, utilisé par l'écran de
  /// démonstration pour déclencher `onUnknownRoute` (TP 3, écran 404).
  static const String demoUnknownRoute = '/__route-de-demo-inconnue__';
}
