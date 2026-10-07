import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/event.dart';
import '../../domain/models/write_status.dart';
import '../../domain/repositories/organizer_event_repository.dart';
import 'firebase_failure_mapper.dart';

/// Événements d'organisateur dans la collection Firestore `events`.
///
/// L'isolation entre comptes est imposée **deux fois** : la requête filtre sur
/// `ownerId`, et `firestore.rules` refuse toute lecture ou écriture d'un
/// document dont `ownerId` n'est pas l'UID connecté. La première sert
/// l'interface, la seconde est la seule vraie protection.
class FirestoreEventRepository implements OrganizerEventRepository {
  FirestoreEventRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  @override
  Stream<List<Event>> watchOwnEvents(String ownerId) {
    // Pas de `orderBy` côté serveur : combiné au filtre d'égalité, il
    // exigerait un index composite. Le tri par date se fait ici.
    return _events
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map(
          (snapshot) =>
              [for (final doc in snapshot.docs) _fromDoc(doc.id, doc.data())]
                ..sort((a, b) => a.start.compareTo(b.start)),
        )
        .handleError((Object error) => throw mapFirestoreError(error));
  }

  @override
  Future<WriteStatus> create(Event event) {
    return awaitWrite(
      _events.doc().set({
        ..._toDoc(event),
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  @override
  Future<WriteStatus> update(Event event) =>
      awaitWrite(_events.doc(event.id).update(_toDoc(event)));

  @override
  Future<WriteStatus> delete(String eventId) =>
      awaitWrite(_events.doc(eventId).delete());

  static Map<String, dynamic> _toDoc(Event event) => {
    'title': event.title,
    'description': event.description,
    'category': event.category,
    'start': Timestamp.fromDate(event.start),
    'end': Timestamp.fromDate(event.end),
    'location': event.location,
    'isOnline': event.isOnline,
    'capacity': event.capacity,
    'price': event.price,
    'ownerId': event.ownerId,
  };

  /// Lecture tolérante : un champ absent ou mal typé prend une valeur par
  /// défaut plutôt que de faire échouer toute la liste (les documents créés
  /// par une version antérieure de l'application n'ont pas tous les champs).
  static Event _fromDoc(String id, Map<String, dynamic> data) {
    final start = data['start'];
    final end = data['end'];
    final startDate = start is Timestamp ? start.toDate() : DateTime.now();
    final capacity = data['capacity'];
    final price = data['price'];
    return Event(
      id: id,
      title: data['title'] is String ? data['title'] as String : '(sans titre)',
      description: data['description'] is String
          ? data['description'] as String
          : '',
      category: data['category'] is String ? data['category'] as String : '',
      start: startDate,
      end: end is Timestamp
          ? end.toDate()
          : startDate.add(const Duration(hours: 2)),
      location: data['location'] is String ? data['location'] as String : '',
      isOnline: data['isOnline'] == true,
      capacity: capacity is int ? capacity : 0,
      // Le compteur d'inscrits n'est pas stocké sur le document : il est
      // reconstitué à partir des inscriptions de l'utilisateur (voir README).
      registered: 0,
      price: price is num ? price.toDouble() : 0,
      ownerId: data['ownerId'] is String ? data['ownerId'] as String : null,
    );
  }
}
