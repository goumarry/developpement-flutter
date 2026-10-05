import 'participant.dart';

/// Une page de la réponse paginée `/users` ou `/users/search`.
///
/// Porte le `total` renvoyé par le serveur, qui permet à l'écran d'annuaire
/// de savoir quand arrêter de paginer sans deviner une valeur (cf. TP §
/// "Pagination par pages de 20").
class UsersPage {
  const UsersPage({
    required this.participants,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<Participant> participants;
  final int total;
  final int skip;
  final int limit;

  factory UsersPage.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'];
    final participants = rawUsers is List
        ? rawUsers
            .whereType<Map>()
            .map((e) => Participant.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <Participant>[];
    return UsersPage(
      participants: participants,
      total: _readInt(json['total']),
      skip: _readInt(json['skip']),
      limit: _readInt(json['limit']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
