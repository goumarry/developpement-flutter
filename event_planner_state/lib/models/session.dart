/// Une session (créneau) d'un événement. Donnée immuable, codée en dur dans le
/// dépôt en mémoire.
class Session {
  const Session({
    required this.id,
    required this.label,
    required this.schedule,
  });

  final String id;

  /// Libellé lisible, ex. « Track technique ».
  final String label;

  /// Horaire sous forme de chaîne, ex. « 9h00 – 10h30 » (aucun parsing attendu).
  final String schedule;
}
