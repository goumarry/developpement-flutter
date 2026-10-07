import '../models/event.dart';
import '../models/event_page.dart';

/// Accès en lecture au catalogue public d'événements.
///
/// Contrat d'erreur : toute implémentation lève une `AppFailure`
/// (`domain/failures.dart`), jamais une exception technique de sa propre
/// bibliothèque.
abstract class EventRepository {
  Future<EventPage> fetchEvents({
    required int limit,
    required int skip,
    String? query,
  });

  Future<Event> fetchEventById(String id);
}
