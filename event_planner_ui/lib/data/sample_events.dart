class Event {
  const Event({
    required this.title,
    required this.city,
    required this.venue,
    required this.date,
    required this.category,
    required this.capacity,
    required this.registered,
    required this.imageUrl,
    this.isSoldOut = false,
    this.isOnline = false,
  });

  final String title;
  final String city;
  final String venue;
  final DateTime date;
  final String category;
  final int capacity;
  final int registered;
  final String imageUrl;
  final bool isSoldOut;
  final bool isOnline;
}

final List<Event> sampleEvents = [
  // Cas 1 : titre très long (> 70 caractères) -> teste le débordement du titre.
  Event(
    title:
        "Conférence annuelle sur l'ingénierie des systèmes distribués et la résilience des architectures cloud",
    city: 'Paris',
    venue: 'Centre des congrès de la Villette',
    date: DateTime(2026, 6, 12, 18, 30),
    category: 'Conférence',
    capacity: 300,
    registered: 274,
    imageUrl: 'https://picsum.photos/seed/event1/200/200',
  ),
  // Cas 2 : événement complet -> teste le badge "Complet" et la jauge à 100%.
  Event(
    title: 'Atelier Flutter : composition avancée',
    city: 'Lyon',
    venue: 'La Cordée Part-Dieu',
    date: DateTime(2026, 6, 20, 9, 0),
    category: 'Atelier',
    capacity: 40,
    registered: 40,
    imageUrl: 'https://picsum.photos/seed/event2/200/200',
    isSoldOut: true,
  ),
  // Cas 3 : événement en ligne, ville/lieu non renseignés -> teste le repli du libellé de localisation.
  Event(
    title: 'Meetup mensuel Dart & Flutter',
    city: '',
    venue: '',
    date: DateTime(2026, 6, 25, 19, 0),
    category: 'Meetup',
    capacity: 500,
    registered: 120,
    imageUrl: 'https://picsum.photos/seed/event3/200/200',
    isOnline: true,
  ),
  // Cas 4 : liste d'attente, registered > capacity -> teste le clamp de la jauge à 1.0.
  Event(
    title: 'Table ronde : éthique et intelligence artificielle',
    city: 'Marseille',
    venue: 'Palais du Pharo',
    date: DateTime(2026, 7, 2, 17, 0),
    category: 'Table ronde',
    capacity: 150,
    registered: 158,
    imageUrl: 'https://picsum.photos/seed/event4/200/200',
  ),
  // Cas 5 : nom de lieu long -> teste l'ellipsis de la ligne "lieu".
  Event(
    title: 'Introduction au Clean Architecture',
    city: 'Toulouse',
    venue: 'Centre de congrès Pierre Baudis, grande salle Occitanie niveau 2',
    date: DateTime(2026, 7, 9, 14, 0),
    category: 'Atelier',
    capacity: 60,
    registered: 12,
    imageUrl: 'https://picsum.photos/seed/event5/200/200',
  ),
  Event(
    title: 'Meetup Kubernetes & microservices',
    city: 'Nantes',
    venue: 'Le Solilab',
    date: DateTime(2026, 7, 15, 18, 0),
    category: 'Meetup',
    capacity: 80,
    registered: 45,
    imageUrl: 'https://picsum.photos/seed/event6/200/200',
  ),
  // Cas 6 : 0 inscrit -> teste la jauge vide.
  Event(
    title: 'Conférence sur la sécurité des applications mobiles',
    city: 'Lille',
    venue: 'Grand Palais',
    date: DateTime(2026, 7, 22, 9, 30),
    category: 'Conférence',
    capacity: 200,
    registered: 0,
    imageUrl: 'https://picsum.photos/seed/event7/200/200',
  ),
  Event(
    title: 'Table ronde développeurs indépendants',
    city: 'Bordeaux',
    venue: 'Rocher de Palmer',
    date: DateTime(2026, 8, 1, 18, 30),
    category: 'Table ronde',
    capacity: 100,
    registered: 90,
    imageUrl: 'https://picsum.photos/seed/event8/200/200',
  ),
];
