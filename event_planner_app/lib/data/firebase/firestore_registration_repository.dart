import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/registration.dart';
import '../../domain/models/write_status.dart';
import '../../domain/repositories/registration_repository.dart';
import 'firebase_failure_mapper.dart';

/// Inscriptions confirmées dans la collection Firestore `registrations`.
///
/// L'identifiant de document est **déterministe** :
/// `<uid>_<eventId>_<courriel normalisé>`. Une seconde inscription de la même
/// personne au même événement vise donc le même document ; comme les règles
/// interdisent toute mise à jour, le serveur la refuse. Le doublon est ainsi
/// bloqué côté serveur, pas seulement par `RegistrationCartState`.
class FirestoreRegistrationRepository implements RegistrationRepository {
  FirestoreRegistrationRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _registrations =>
      _db.collection('registrations');

  static String _docId(Registration registration) =>
      '${registration.userId}_${registration.eventId}_'
      '${registration.participantKey}';

  @override
  Stream<List<Registration>> watchConfirmed(String userId) {
    return _registrations
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              [for (final doc in snapshot.docs) ?_fromDoc(doc.id, doc.data())]
                ..sort((a, b) => a.eventTitle.compareTo(b.eventTitle)),
        )
        .handleError((Object error) => throw mapFirestoreError(error));
  }

  /// Un seul lot : toutes les inscriptions sont écrites, ou aucune.
  @override
  Future<WriteStatus> confirmAll(List<Registration> registrations) {
    final batch = _db.batch();
    for (final registration in registrations) {
      batch.set(_registrations.doc(_docId(registration)), {
        'userId': registration.userId,
        'eventId': registration.eventId,
        'eventTitle': registration.eventTitle,
        'participantName': registration.participantName,
        'participantEmail': registration.participantKey,
        'seats': registration.seats,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return awaitWrite(batch.commit());
  }

  @override
  Future<WriteStatus> cancel(String registrationId) =>
      awaitWrite(_registrations.doc(registrationId).delete());

  /// `null` pour un document mal formé : il est ignoré plutôt que de faire
  /// échouer toute la liste.
  static Registration? _fromDoc(String id, Map<String, dynamic> data) {
    try {
      return Registration.fromJson({...data, 'id': id});
    } on FormatException {
      return null;
    }
  }
}
