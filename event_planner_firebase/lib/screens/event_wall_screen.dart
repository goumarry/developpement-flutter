import 'package:flutter/material.dart';

import '../data/event_repository.dart';
import '../routes/app_routes.dart';
import '../widgets/category_filters.dart';
import '../widgets/event_card.dart';
import '../widgets/hero_header.dart';
import '../widgets/section_header.dart';
import '../widgets/stats_bar.dart';

/// Écran d'accueil « mur d'événements », repris du TP 2/3 — mise en page pure,
/// aucun état applicatif (ni Provider, ni filtre fonctionnel : ça, c'est
/// l'écran « Événements » du TP 4, `EventListScreen`).
///
/// TP 3 : chaque [EventCard] est cliquable et ouvre le détail via une
/// **route nommée** en passant l'identifiant stable de l'événement
/// (`event.id`), jamais l'objet complet.
class EventWallScreen extends StatelessWidget {
  const EventWallScreen({super.key});

  static const _repository = EventRepository();

  @override
  Widget build(BuildContext context) {
    final events = _repository.allEvents();
    final categories = events.map((e) => e.category).toSet().toList();
    final totalRegistered =
        events.fold<int>(0, (sum, e) => sum + e.registered);

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
                  StatItem(value: '${events.length}', label: 'événements'),
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
                count: events.length,
              ),
            ),
            for (final event in events)
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
