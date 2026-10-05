import 'session.dart';

/// Modèle métier d'un événement — **Dart pur**, aucune dépendance Flutter.
///
/// Repris du fil rouge (TP 2/3) et resserré pour le TP 4 sur les seuls champs
/// utiles : identité, titre, catégorie, capacité totale, places déjà prises
/// (hors panier) et liste de sessions. Le champ [date] est conservé pour
/// permettre le tri « par date » des préférences d'affichage.
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.capacity,
    required this.taken,
    this.imageUrl = '',
    this.sessions = const [],
  });

  /// Identifiant stable et unique (ex. `evt-001`).
  final String id;
  final String title;
  final String category;
  final DateTime date;

  /// Vignette de démonstration (reprise du fil rouge, TP 2/3). Purement
  /// illustrative — ce n'est pas une source de données.
  final String imageUrl;

  /// Capacité totale de l'événement.
  final int capacity;

  /// Places déjà prises **en dehors** du panier de l'utilisateur courant.
  final int taken;

  final List<Session> sessions;

  /// Places restantes vis-à-vis des seules réservations déjà confirmées
  /// (le panier local n'entre pas dans ce calcul — c'est [RegistrationCart]
  /// qui combine les deux).
  int get remainingSeats {
    final left = capacity - taken;
    return left < 0 ? 0 : left;
  }
}
