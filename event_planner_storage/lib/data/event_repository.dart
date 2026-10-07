import '../models/event.dart';
import '../models/session.dart';

/// Dépôt de données **en mémoire, codé en dur**. Aucune source externe, aucune
/// mutation : la liste est exposée en lecture seule. Les seules données
/// mutables de l'application vivent dans les notifiers de `lib/state/`.
///
/// Fusion fil-rouge : capacité/places prises/sessions viennent du TP 4 ;
/// ville/lieu/en-ligne viennent du TP 2/TP 3 (mêmes `id`, cas limites de mise
/// en page conservés : titre long, événement complet, événement en ligne sans
/// localisation, sur-réservation, nom de lieu long, jauge vide).
class EventRepository {
  const EventRepository();

  static final List<Event> _events = [
    Event(
      id: 'evt-001',
      imageUrl: 'https://picsum.photos/seed/evt-001/240/240',
      title:
          "Conférence annuelle sur l'ingénierie des systèmes distribués et la résilience des architectures cloud",
      category: 'Conférence',
      date: DateTime(2026, 6, 12, 18, 30),
      city: 'Paris',
      venue: 'Centre des congrès de la Villette',
      capacity: 300,
      taken: 274,
      sessions: const [
        Session(id: 's1', label: 'Keynote d\'ouverture', schedule: '18h30 – 19h15'),
        Session(id: 's2', label: 'Track résilience', schedule: '19h30 – 20h30'),
        Session(id: 's3', label: 'Track observabilité', schedule: '19h30 – 20h30'),
      ],
    ),
    // Événement volontairement COMPLET : démontre le refus « complet » (TP 4)
    // et le badge "Complet" (TP 2/3).
    Event(
      id: 'evt-002',
      imageUrl: 'https://picsum.photos/seed/evt-002/240/240',
      title: 'Atelier Flutter : composition avancée',
      category: 'Atelier',
      date: DateTime(2026, 6, 20, 9, 0),
      city: 'Lyon',
      venue: 'La Cordée Part-Dieu',
      capacity: 40,
      taken: 40,
      sessions: const [
        Session(id: 's1', label: 'Matinée guidée', schedule: '9h00 – 12h00'),
        Session(id: 's2', label: 'Après-midi projet', schedule: '13h30 – 17h00'),
      ],
    ),
    // En ligne, ville/lieu non renseignés -> teste le repli du libellé de
    // localisation (TP 2/3).
    Event(
      id: 'evt-003',
      imageUrl: 'https://picsum.photos/seed/evt-003/240/240',
      title: 'Meetup mensuel Dart & Flutter',
      category: 'Meetup',
      date: DateTime(2026, 6, 25, 19, 0),
      isOnline: true,
      capacity: 120,
      taken: 61,
      sessions: const [
        Session(id: 's1', label: 'Lightning talks', schedule: '19h00 – 20h00'),
        Session(id: 's2', label: 'Discussions libres', schedule: '20h00 – 21h30'),
      ],
    ),
    // Presque complet : 2 places restantes -> démontre le calcul
    // « places prises + panier >= capacité » (TP 4).
    Event(
      id: 'evt-004',
      imageUrl: 'https://picsum.photos/seed/evt-004/240/240',
      title: 'Table ronde : éthique et intelligence artificielle',
      category: 'Table ronde',
      date: DateTime(2026, 7, 2, 17, 0),
      city: 'Marseille',
      venue: 'Palais du Pharo',
      capacity: 30,
      taken: 28,
      sessions: const [
        Session(id: 's1', label: 'Panel principal', schedule: '17h00 – 18h30'),
        Session(id: 's2', label: 'Questions du public', schedule: '18h30 – 19h00'),
      ],
    ),
    // Nom de lieu long -> teste l'ellipsis de la ligne "lieu" (TP 2/3).
    Event(
      id: 'evt-005',
      imageUrl: 'https://picsum.photos/seed/evt-005/240/240',
      title: 'Introduction au Clean Architecture',
      category: 'Atelier',
      date: DateTime(2026, 7, 9, 14, 0),
      city: 'Toulouse',
      venue: 'Centre de congrès Pierre Baudis, grande salle Occitanie niveau 2',
      capacity: 60,
      taken: 12,
      sessions: const [
        Session(id: 's1', label: 'Fondamentaux', schedule: '14h00 – 15h30'),
        Session(id: 's2', label: 'Cas pratique', schedule: '15h45 – 17h30'),
      ],
    ),
    Event(
      id: 'evt-006',
      imageUrl: 'https://picsum.photos/seed/evt-006/240/240',
      title: 'Meetup Kubernetes & microservices',
      category: 'Meetup',
      date: DateTime(2026, 7, 15, 18, 0),
      city: 'Nantes',
      venue: 'Le Solilab',
      capacity: 80,
      taken: 45,
      sessions: const [
        Session(id: 's1', label: 'Retours d\'expérience', schedule: '18h00 – 19h30'),
        Session(id: 's2', label: 'Atelier réseau', schedule: '19h30 – 20h30'),
      ],
    ),
    // 0 inscrit -> teste la jauge vide (TP 2/3).
    Event(
      id: 'evt-007',
      imageUrl: 'https://picsum.photos/seed/evt-007/240/240',
      title: 'Conférence sécurité des applications mobiles',
      category: 'Conférence',
      date: DateTime(2026, 7, 22, 9, 30),
      city: 'Lille',
      venue: 'Grand Palais',
      capacity: 200,
      taken: 0,
      sessions: const [
        Session(id: 's1', label: 'Menaces courantes', schedule: '9h30 – 11h00'),
        Session(id: 's2', label: 'Durcissement', schedule: '11h15 – 12h30'),
        Session(id: 's3', label: 'Table ronde RSSI', schedule: '14h00 – 15h30'),
      ],
    ),
    Event(
      id: 'evt-008',
      imageUrl: 'https://picsum.photos/seed/evt-008/240/240',
      title: 'Table ronde développeurs indépendants',
      category: 'Table ronde',
      date: DateTime(2026, 8, 1, 18, 30),
      city: 'Bordeaux',
      venue: 'Rocher de Palmer',
      capacity: 100,
      taken: 90,
      sessions: const [
        Session(id: 's1', label: 'Se lancer', schedule: '18h30 – 19h30'),
        Session(id: 's2', label: 'Tarification & clients', schedule: '19h30 – 20h30'),
      ],
    ),
  ];

  /// Copie non modifiable de la liste d'événements.
  List<Event> allEvents() => List.unmodifiable(_events);

  /// Résout un identifiant, ou `null` s'il n'existe pas.
  Event? findById(String id) {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Catégories distinctes présentes dans le jeu de données, triées.
  List<String> categories() {
    final set = <String>{for (final e in _events) e.category};
    final list = set.toList()..sort();
    return list;
  }
}
