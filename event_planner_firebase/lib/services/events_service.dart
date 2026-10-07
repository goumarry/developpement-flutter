import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/organizer_event.dart';

/// Accès Firestore à la collection `events` (TP 8, partie C).
class EventsService {
  EventsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  /// Flux temps réel des événements de [uid].
  ///
  /// `where(ownerId ==)` seul : ajouter `orderBy('createdAt')` exigerait un
  /// index composite (voir [queryNeedingCompositeIndex]). Le tri est donc fait
  /// côté client dans l'écran. `includeMetadataChanges: true` : on est notifié
  /// aussi quand `isFromCache` / `hasPendingWrites` changent (confirmation
  /// serveur), pas seulement quand les données changent.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchOwnEvents(String uid) =>
      _events
          .where('ownerId', isEqualTo: uid)
          .snapshots(includeMetadataChanges: true);

  Future<void> add({
    required String uid,
    required String title,
    required String location,
    required DateTime date,
  }) async {
    // Ce Future ne se résout qu'à la confirmation SERVEUR : hors ligne, il
    // reste en attente. L'appelant ne doit donc pas bloquer l'interface
    // dessus — le flux `snapshots()` reflète l'écriture dès le cache local.
    await _events.add({
      'title': title,
      'ownerId': uid,
      'location': location,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rename(String eventId, String title) =>
      _events.doc(eventId).update({'title': title});

  Future<void> delete(String eventId) => _events.doc(eventId).delete();

  /// Écriture « sauvage » sur un document dont on connaît l'identifiant, quel
  /// qu'en soit le propriétaire : sert à PROUVER que les règles refusent la
  /// modification de l'événement d'un autre organisateur (écran de
  /// diagnostic).
  Future<void> tryUpdateAnyEvent(String eventId) =>
      _events.doc(eventId).update({'title': 'modifié sans droit ?'});

  /// Lecture de TOUTE la collection, sans filtre `ownerId` : refusée par les
  /// règles (une requête doit être prouvée conforme aux règles dans sa
  /// totalité). Écran de diagnostic.
  Future<QuerySnapshot<Map<String, dynamic>>> tryReadAllEvents() =>
      _events.get();

  /// Requête VOLONTAIREMENT sans index : égalité sur `ownerId` + tri sur
  /// `date`. Firestore répond `failed-precondition` avec un lien de création
  /// de l'index composite (README, partie C).
  Future<QuerySnapshot<Map<String, dynamic>>> queryNeedingCompositeIndex(
    String uid,
  ) =>
      _events
          .where('ownerId', isEqualTo: uid)
          .orderBy('date', descending: true)
          .get();

  /// Convertit un snapshot en modèles triés du plus récent au plus ancien.
  /// `createdAt == null` (écriture locale non confirmée) : en tête, c'est
  /// l'événement que l'utilisateur vient de créer.
  static List<OrganizerEvent> toSortedEvents(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final events = snapshot.docs.map(OrganizerEvent.fromSnapshot).toList();
    events.sort((a, b) {
      final ca = a.createdAt;
      final cb = b.createdAt;
      if (ca == null && cb == null) return 0;
      if (ca == null) return -1;
      if (cb == null) return 1;
      return cb.compareTo(ca);
    });
    return events;
  }
}
