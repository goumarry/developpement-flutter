/// Modèle métier d'un événement.
///
/// Repris **à l'identique du TP 2**, avec un seul ajout imposé par l'énoncé du
/// TP 3 : un champ [id] stable. Cet identifiant est la clé qui circule dans les
/// arguments de route (Partie C) : il ne doit jamais être recalculé, seulement
/// transporté puis résolu vers l'objet complet via le jeu de données.
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.city,
    required this.venue,
    required this.date,
    required this.category,
    required this.capacity,
    required this.registered,
    required this.imageUrl,
    this.isSoldOut = false,
    this.isOnline = false,
  });

  /// Identifiant stable et unique (ex. `evt-001`). Sert de clé de route.
  final String id;
  final String title;
  final String city;
  final String venue;
  final DateTime date;
  final String category;
  final int capacity;
  final int registered;
  final String imageUrl;
  final bool isSoldOut;
  final bool isOnline;

  /// Nombre de places encore disponibles (jamais négatif).
  int get remainingSeats =>
      (capacity - registered) < 0 ? 0 : capacity - registered;
}
