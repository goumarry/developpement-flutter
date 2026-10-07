import 'package:cloud_firestore/cloud_firestore.dart';

/// Événement stocké dans la collection Firestore `events` (TP 8).
///
/// Distinct du modèle [Event] du fil rouge (mur / panier, données locales) :
/// celui-ci appartient à un organisateur ([ownerId]) et vit côté serveur.
/// L'identifiant de document est généré par Firestore (`add`) — jamais l'UID,
/// car un organisateur crée plusieurs événements.
class OrganizerEvent {
  const OrganizerEvent({
    required this.id,
    required this.title,
    required this.ownerId,
    this.location = '',
    this.date,
    this.createdAt,
    this.isFromCache = false,
    this.hasPendingWrites = false,
  });

  final String id;
  final String title;
  final String ownerId;
  final String location;
  final DateTime? date;

  /// `null` tant que le serveur n'a pas résolu `FieldValue.serverTimestamp()`
  /// (écriture locale en attente de confirmation).
  final DateTime? createdAt;

  /// Provenance de la donnée (métadonnées du snapshot) : cache local vs
  /// serveur. Voir README, partie C.
  final bool isFromCache;

  /// Écriture locale pas encore confirmée par le serveur.
  final bool hasPendingWrites;

  factory OrganizerEvent.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return OrganizerEvent(
      id: doc.id,
      title: (data['title'] as String?) ?? '(sans titre)',
      ownerId: (data['ownerId'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      date: (data['date'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isFromCache: doc.metadata.isFromCache,
      hasPendingWrites: doc.metadata.hasPendingWrites,
    );
  }
}
