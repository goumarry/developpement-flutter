import 'event.dart';

/// Une page de résultats du catalogue, avec le [total] annoncé par le serveur
/// (c'est lui qui permet de savoir quand arrêter de paginer).
class EventPage {
  EventPage({
    required List<Event> events,
    required this.total,
    required this.skip,
    required this.limit,
  }) : events = List.unmodifiable(events);

  final List<Event> events;
  final int total;
  final int skip;
  final int limit;
}
