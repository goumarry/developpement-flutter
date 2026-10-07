import 'package:flutter/material.dart';

import '../../domain/models/event.dart';
import '../utils/formatters.dart';
import 'capacity_gauge.dart';
import 'event_image.dart';

/// Carte d'événement, réutilisée par le catalogue et l'espace organisateur.
///
/// Deux dispositions, choisies par l'appelant selon la largeur disponible :
/// horizontale (vignette à gauche — liste sur téléphone) ou [vertical]
/// (visuel en haut — tuile de grille sur tablette).
///
/// Sans débordement : chaque texte est borné (`maxLines` + ellipse) et placé
/// dans un `Expanded`, aucune hauteur n'est fixée sur un bloc de texte.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.vertical = false,
    this.trailing,
  });

  final Event event;
  final VoidCallback? onTap;
  final bool vertical;

  /// Action secondaire (menu de l'organisateur), en haut à droite.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final details = _EventCardDetails(event: event, trailing: trailing);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: EventImage(event: event)),
                  Padding(padding: const EdgeInsets.all(12), child: details),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: EventImage(event: event),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EventCardDetails extends StatelessWidget {
  const _EventCardDetails({required this.event, this.trailing});

  final Event event;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 4),
        Text(
          dateLabel(event.start),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: muted,
        ),
        Text(
          '${event.category.isEmpty ? 'Divers' : event.category} · '
          '${priceLabel(event.price)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: muted,
        ),
        const SizedBox(height: 8),
        CapacityGauge(taken: event.registered, capacity: event.capacity),
      ],
    );
  }
}
