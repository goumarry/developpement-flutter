/// Verdict du contrôle de capacité.
enum CapacityDecision {
  accepted,

  /// L'événement a déjà atteint sa capacité (égalité stricte comprise).
  rejectedFull,

  /// Il reste des places, mais moins que le nombre demandé.
  rejectedNotEnoughSeats,

  /// Nombre de places demandé nul ou négatif.
  rejectedInvalidSeats;

  bool get isAccepted => this == accepted;
}

/// Règle de capacité — **fonctions pures**, sans Flutter ni état : c'est le
/// seul endroit de l'application qui décide si une inscription tient dans un
/// événement.
abstract final class CapacityRule {
  /// Places encore disponibles, jamais négatives (une source incohérente où
  /// `taken > capacity` donne 0, pas un nombre négatif).
  static int remaining({required int capacity, required int taken}) =>
      taken >= capacity ? 0 : capacity - taken;

  /// [taken] = toutes les places déjà prises (source + inscriptions de
  /// l'utilisateur, confirmées ou en cours).
  ///
  /// * `taken == capacity` -> refus ([CapacityDecision.rejectedFull]) ;
  /// * `taken + requestedSeats == capacity` -> accepté : la dernière place
  ///   disponible peut être prise ;
  /// * `taken + requestedSeats > capacity` -> refus.
  static CapacityDecision check({
    required int capacity,
    required int taken,
    required int requestedSeats,
  }) {
    if (requestedSeats < 1) return CapacityDecision.rejectedInvalidSeats;
    if (taken >= capacity) return CapacityDecision.rejectedFull;
    if (taken + requestedSeats > capacity) {
      return CapacityDecision.rejectedNotEnoughSeats;
    }
    return CapacityDecision.accepted;
  }
}
