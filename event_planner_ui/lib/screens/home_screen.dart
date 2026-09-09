import 'package:flutter/material.dart';

import '../data/sample_events.dart';
import '../widgets/category_filters.dart';
import '../widgets/event_card.dart';
import '../widgets/hero_header.dart';
import '../widgets/section_header.dart';
import '../widgets/stats_bar.dart';

/// Écran d'accueil "mur d'événements". Toute la page défile en un seul
/// mouvement via un unique [SingleChildScrollView] : la liste d'événements
/// est rendue avec un simple `.map()` dans la [Column] plutôt qu'avec un
/// [ListView] imbriqué, pour ne jamais avoir deux zones défilantes emboîtées.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = sampleEvents.map((e) => e.category).toSet().toList();
    final totalRegistered = sampleEvents.fold<int>(0, (sum, e) => sum + e.registered);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Planner')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HeroHeader(
              title: 'Cycle Systèmes Distribuédeefzfv zvzvzdvevs',
              tagline: "Conférences, ateliers et meetups toute l'année",
              backgroundImageUrl: 'https://picsum.photos/seed/hero/800/400',
              avatarImageUrl: 'https://picsum.photos/seed/avatar/200/200',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: StatsBar(
                items: [
                  StatItem(value: '${sampleEvents.length}', label: 'événements'),
                  StatItem(value: '${categories.length}', label: 'catégories'),
                  StatItem(value: '$totalRegistered', label: 'inscrits'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: CategoryFilters(categories: categories),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: SectionHeader(
                title: 'Prochains événements',
                count: sampleEvents.length,
              ),
            ),
            for (final event in sampleEvents) EventCard(event: event),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '© 2026 Event Planner — Tous droits réservés',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
