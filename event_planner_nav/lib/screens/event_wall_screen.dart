import 'package:flutter/material.dart';

import '../data/sample_events.dart';
import '../routes/app_routes.dart';
import '../widgets/category_filters.dart';
import '../widgets/event_card.dart';
import '../widgets/hero_header.dart';
import '../widgets/section_header.dart';
import '../widgets/stats_bar.dart';

/// Écran d'accueil « mur d'événements », repris du TP 2.
///
/// TP 3 : chaque [EventCard] devient cliquable et ouvre le détail via une
/// **route nommée** en passant l'identifiant stable de l'événement
/// (`event.id`), jamais l'objet complet.
///
/// La page défile toujours en un seul mouvement via un unique
/// [SingleChildScrollView] ; au retour du détail, la position de défilement
/// est conservée car l'écran n'est pas reconstruit (il reste au fond de la
/// pile du Navigator).
class EventWallScreen extends StatelessWidget {
  const EventWallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = sampleEvents.map((e) => e.category).toSet().toList();
    final totalRegistered =
        sampleEvents.fold<int>(0, (sum, e) => sum + e.registered);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Planner')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HeroHeader(
              title: 'Cycle Systèmes Distribués',
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
            for (final event in sampleEvents)
              EventCard(
                event: event,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.eventDetail,
                  arguments: event.id,
                ),
              ),
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
