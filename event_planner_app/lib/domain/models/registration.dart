/// Inscription d'un participant à un événement — immuable, Dart pur.
///
/// Sert aux deux étapes : ligne du panier (« en cours », [id] vide et
/// [userId] vide) puis inscription confirmée (document Firestore).
class Registration {
  const Registration({
    required this.eventId,
    required this.eventTitle,
    required this.participantName,
    required this.participantEmail,
    required this.seats,
    this.id = '',
    this.userId = '',
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    final eventId = json['eventId'];
    final email = json['participantEmail'];
    final seats = json['seats'];
    if (eventId is! String || email is! String || seats is! int) {
      throw const FormatException('Inscription JSON invalide');
    }
    return Registration(
      id: json['id'] is String ? json['id'] as String : '',
      userId: json['userId'] is String ? json['userId'] as String : '',
      eventId: eventId,
      eventTitle: json['eventTitle'] is String
          ? json['eventTitle'] as String
          : '',
      participantName: json['participantName'] is String
          ? json['participantName'] as String
          : '',
      participantEmail: email,
      seats: seats,
    );
  }

  /// Identifiant du document une fois confirmée ; vide dans le panier.
  final String id;

  /// UID du compte qui a confirmé l'inscription ; vide dans le panier.
  final String userId;
  final String eventId;

  /// Titre recopié : la liste des inscriptions reste lisible hors connexion,
  /// sans recharger l'événement.
  final String eventTitle;
  final String participantName;
  final String participantEmail;
  final int seats;

  /// Courriel normalisé : c'est lui qui identifie « la même personne ».
  String get participantKey => participantEmail.trim().toLowerCase();

  /// Deux inscriptions sont en doublon si elles visent le même événement pour
  /// la même personne, quel que soit le nombre de places.
  bool isDuplicateOf(Registration other) =>
      other.eventId == eventId && other.participantKey == participantKey;

  Registration copyWith({String? id, String? userId, int? seats}) {
    return Registration(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId,
      eventTitle: eventTitle,
      participantName: participantName,
      participantEmail: participantEmail,
      seats: seats ?? this.seats,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'eventId': eventId,
    'eventTitle': eventTitle,
    'participantName': participantName,
    'participantEmail': participantEmail,
    'seats': seats,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Registration &&
          other.id == id &&
          other.userId == userId &&
          other.eventId == eventId &&
          other.eventTitle == eventTitle &&
          other.participantName == participantName &&
          other.participantEmail == participantEmail &&
          other.seats == seats;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    eventId,
    eventTitle,
    participantName,
    participantEmail,
    seats,
  );

  @override
  String toString() => 'Registration($eventId, $participantKey, $seats)';
}
