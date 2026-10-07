import 'package:flutter/material.dart';

import '../../domain/models/event.dart';
import '../utils/breakpoints.dart';
import 'event_card.dart';

/// Collection d'événements **adaptative**, sous forme de sliver : à placer
/// dans un `CustomScrollView`, entre d'éventuels en-têtes et pieds de liste.
///
/// * largeur < [Breakpoints.tablet] : liste, cartes horizontales ;
/// * au-delà : grille de tuiles verticales, dont le nombre de colonnes suit
///   la largeur (`maxCrossAxisExtent`).
///
/// La mise en page est réorganisée, pas mise à l'échelle : la carte change de
/// disposition et la hauteur des tuiles tient compte de la taille de police
/// choisie par l'utilisateur (`textScaler`), pour ne jamais déborder.
class EventCollectionSliver extends StatelessWidget {
  const EventCollectionSliver({
    super.key,
    required this.events,
    required this.onTap,
    this.trailingBuilder,
  });

  final List<Event> events;
  final ValueChanged<Event> onTap;
  final Widget Function(Event event)? trailingBuilder;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.crossAxisExtent >= Breakpoints.tablet;
        Widget card(BuildContext context, int index) {
          final event = events[index];
          return EventCard(
            key: ValueKey(event.id),
            event: event,
            vertical: isWide,
            onTap: () => onTap(event),
            trailing: trailingBuilder?.call(event),
          );
        }

        if (!isWide) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            sliver: SliverList.separated(
              itemCount: events.length,
              itemBuilder: card,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              // Visuel de hauteur fixe + bloc de texte qui grandit avec la
              // taille de police.
              mainAxisExtent: 140 + 150 * textScale,
            ),
            itemCount: events.length,
            itemBuilder: card,
          ),
        );
      },
    );
  }
}
