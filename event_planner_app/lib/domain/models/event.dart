/// Événement — modèle de domaine **immuable**, Dart pur (aucun import Flutter).
///
/// Un seul modèle pour les deux sources de l'application : le catalogue public
/// (API distante, [ownerId] nul) et l'espace organisateur (Firestore,
/// [ownerId] = UID du créateur). Les écrans et widgets ne distinguent pas la
/// provenance : `EventCard` ou l'écran de détail servent aux deux.
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.category,
    required this.start,
    required this.end,
    required this.capacity,
    required this.registered,
    this.description = '',
    this.location = '',
    this.isOnline = false,
    this.price = 0,
    this.imageUrl = '',
    this.ownerId,
  });

  /// Reconstruit un événement depuis sa forme JSON ([toJson]). Lève une
  /// [FormatException] si un champ obligatoire est absent ou mal typé.
  factory Event.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final start = DateTime.tryParse('${json['start']}');
    final end = DateTime.tryParse('${json['end']}');
    final capacity = json['capacity'];
    final registered = json['registered'];
    if (id is! String ||
        title is! String ||
        start == null ||
        end == null ||
        capacity is! int ||
        registered is! int) {
      throw const FormatException('Événement JSON invalide');
    }
    final price = json['price'];
    return Event(
      id: id,
      title: title,
      category: json['category'] is String ? json['category'] as String : '',
      start: start,
      end: end,
      capacity: capacity,
      registered: registered,
      description: json['description'] is String
          ? json['description'] as String
          : '',
      location: json['location'] is String ? json['location'] as String : '',
      isOnline: json['isOnline'] == true,
      price: price is num ? price.toDouble() : 0,
      imageUrl: json['imageUrl'] is String ? json['imageUrl'] as String : '',
      ownerId: json['ownerId'] is String ? json['ownerId'] as String : null,
    );
  }

  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime start;
  final DateTime end;

  /// Adresse du lieu ; vide si [isOnline].
  final String location;
  final bool isOnline;

  /// Nombre total de places.
  final int capacity;

  /// Places déjà prises côté source (hors inscriptions de l'utilisateur
  /// courant, que `RegistrationCartState` ajoute au moment du contrôle).
  final int registered;

  /// Tarif en euros ; 0 = gratuit.
  final double price;
  final String imageUrl;

  /// UID de l'organisateur propriétaire, ou `null` pour un événement du
  /// catalogue public.
  final String? ownerId;

  int get remainingSeats => registered >= capacity ? 0 : capacity - registered;

  /// Complet dès que le nombre d'inscrits **atteint** la capacité (égalité
  /// stricte comprise).
  bool get isFull => registered >= capacity;

  bool get isFree => price == 0;

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? start,
    DateTime? end,
    String? location,
    bool? isOnline,
    int? capacity,
    int? registered,
    double? price,
    String? imageUrl,
    String? ownerId,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      start: start ?? this.start,
      end: end ?? this.end,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      capacity: capacity ?? this.capacity,
      registered: registered ?? this.registered,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'location': location,
    'isOnline': isOnline,
    'capacity': capacity,
    'registered': registered,
    'price': price,
    'imageUrl': imageUrl,
    if (ownerId != null) 'ownerId': ownerId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          other.id == id &&
          other.title == title &&
          other.description == description &&
          other.category == category &&
          other.start == start &&
          other.end == end &&
          other.location == location &&
          other.isOnline == isOnline &&
          other.capacity == capacity &&
          other.registered == registered &&
          other.price == price &&
          other.imageUrl == imageUrl &&
          other.ownerId == ownerId;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    category,
    start,
    end,
    location,
    isOnline,
    capacity,
    registered,
    price,
    imageUrl,
    ownerId,
  );

  @override
  String toString() => 'Event($id, $title, $registered/$capacity)';
}
