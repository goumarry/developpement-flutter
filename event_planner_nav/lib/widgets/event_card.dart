import 'package:flutter/material.dart';

import '../models/event.dart';
import '../utils/date_label.dart';
import 'capacity_gauge.dart';

/// Carte d'événement : vignette carrée + bloc titre/lieu/date/jauge.
///
/// Le bloc textuel est placé dans un [Expanded] pour occuper tout l'espace
/// restant à droite de la vignette, quelle que soit la largeur de la carte :
/// c'est ce qui empêche un titre long de pousser la vignette hors de vue.
///
/// TP 3 : le **contrat visuel du TP 2 est inchangé**. Seul un rappel [onTap]
/// optionnel est ajouté ; quand il est fourni, la carte est enveloppée dans un
/// [InkWell] (aucune modification de mise en page, juste l'effet d'encre au
/// toucher).
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, this.onTap});

  final Event event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black12,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _locationLabel(event),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        dateLabel(event.date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    if (event.isSoldOut)
                      const _StatusBadge(label: 'Complet', color: Colors.red)
                    else if (event.isOnline)
                      const _StatusBadge(label: 'En ligne', color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 8),
                CapacityGauge(event: event),
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: onTap == null
          ? card
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: card,
            ),
    );
  }

  String _locationLabel(Event event) {
    if (event.isOnline) return 'Diffusion en ligne';
    if (event.venue.isEmpty && event.city.isEmpty) return 'Lieu à confirmer';
    if (event.venue.isEmpty) return event.city;
    if (event.city.isEmpty) return event.venue;
    return '${event.venue}, ${event.city}';
  }
}

/// Petit badge d'état, réutilisable et paramétré par label/couleur.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
