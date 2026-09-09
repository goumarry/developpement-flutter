import 'route_generator.dart';

/// Noms de route de l'application, sous forme de **constantes typées**.
///
/// Règle du TP : aucune chaîne littérale de route ne doit apparaître ailleurs
/// que dans ce fichier. Tout appel à `pushNamed` / `pushReplacementNamed` /
/// `pushNamedAndRemoveUntil` référence une constante `AppRoutes.xxx`.
///
/// La fabrication effective des routes (résolution des arguments, écrans
/// d'erreur) est déléguée à [RouteGenerator], ré-exporté ici pour que
/// `main.dart` n'ait qu'un seul import de routage.
abstract final class AppRoutes {
  const AppRoutes._();

  /// Mur d'événements (point d'entrée et de retour final).
  static const String home = '/';

  /// Détail d'un événement. Argument attendu : `String id`.
  static const String eventDetail = '/event-detail';

  /// Sélection d'une formule. Argument : `String` (titre de l'événement, pour
  /// l'affichage). Valeur de retour : `Formule?`.
  static const String packageSelection = '/package-selection';

  /// Récapitulatif de réservation. Argument : [ConfirmationArgs].
  static const String confirmation = '/confirmation';

  /// Nom volontairement **non enregistré** dans `RouteGenerator`, utilisé
  /// uniquement par l'écran de démonstration pour déclencher `onUnknownRoute`
  /// (écran 404). N'est associé à aucun écran.
  static const String demoUnknownRoute = '/__route-de-demo-inconnue__';
}
