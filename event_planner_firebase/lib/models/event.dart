import 'session.dart';

/// Modèle métier d'un événement — **Dart pur**, aucune dépendance Flutter.
///
/// Fusion fil-rouge : [capacity]/[taken]/[sessions] viennent du TP 4 (support
/// du panier Provider), [city]/[venue]/[isOnline] viennent du TP 2/TP 3
/// (support du mur d'événements et de sa jauge de localisation). [registered]
/// et [isSoldOut] sont des alias de lecture pour que les widgets repris du
/// TP 2/TP 3 (`EventCard`, `EventWallScreen`) compilent sans modification de
/// leur logique d'origine.
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.capacity,
    required this.taken,
    this.imageUrl = '',
    this.city = '',
    this.venue = '',
    this.isOnline = false,
    this.sessions = const [],
  });

  /// Identifiant stable et unique (ex. `evt-001`), clé de route (TP 3).
  final String id;
  final String title;
  final String category;
  final DateTime date;

  /// Vignette de démonstration (reprise du fil rouge, TP 2/3).
  final String imageUrl;

  final String city;
  final String venue;

  /// Diffusion en ligne : pas de lieu physique à afficher (TP 2/3).
  final bool isOnline;

  /// Capacité totale de l'événement.
  final int capacity;

  /// Places déjà prises **en dehors** du panier de l'utilisateur courant.
  final int taken;

  final List<Session> sessions;

  /// Alias de [taken], au nom utilisé par les widgets du TP 2/TP 3.
  int get registered => taken;

  /// Dérivé de la capacité plutôt que stocké : évite qu'un drapeau édité à la
  /// main se désynchronise de `taken`/`capacity` (ce qui arrivait au TP 3).
  bool get isSoldOut => taken >= capacity;

  /// Places restantes vis-à-vis des seules réservations déjà confirmées
  /// (le panier local n'entre pas dans ce calcul — c'est [RegistrationCart]
  /// qui combine les deux, cf. TP 4).
  int get remainingSeats {
    final left = capacity - taken;
    return left < 0 ? 0 : left;
  }
}
