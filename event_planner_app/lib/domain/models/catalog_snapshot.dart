import 'event.dart';

/// Dernier catalogue chargé avec succès, tel qu'il est conservé sur disque
/// pour le mode dégradé hors connexion.
class CatalogSnapshot {
  CatalogSnapshot({
    required List<Event> events,
    required this.total,
    required this.savedAt,
  }) : events = List.unmodifiable(events);

  factory CatalogSnapshot.fromJson(Map<String, dynamic> json) {
    final events = json['events'];
    final total = json['total'];
    final savedAt = DateTime.tryParse('${json['savedAt']}');
    if (events is! List || total is! int || savedAt == null) {
      throw const FormatException('Instantané de catalogue invalide');
    }
    return CatalogSnapshot(
      events: [
        for (final event in events)
          if (event is Map) Event.fromJson(event.cast<String, dynamic>()),
      ],
      total: total,
      savedAt: savedAt,
    );
  }

  final List<Event> events;
  final int total;

  /// Date de la dernière réponse réussie du serveur.
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'events': [for (final event in events) event.toJson()],
    'total': total,
    'savedAt': savedAt.toIso8601String(),
  };
}
