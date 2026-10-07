import '../models/event.dart';
import '../models/write_status.dart';

/// Événements créés par un organisateur (collection protégée côté serveur).
abstract class OrganizerEventRepository {
  /// Flux temps réel des événements dont [ownerId] est propriétaire — et
  /// d'eux seuls : la requête est filtrée, et les règles de sécurité refusent
  /// toute lecture plus large.
  Stream<List<Event>> watchOwnEvents(String ownerId);

  /// Crée l'événement. `event.ownerId` doit être l'UID de l'utilisateur
  /// connecté (vérifié par les règles) ; `event.id` est ignoré, l'identifiant
  /// est généré par le serveur.
  Future<WriteStatus> create(Event event);

  Future<WriteStatus> update(Event event);

  Future<WriteStatus> delete(String eventId);
}
