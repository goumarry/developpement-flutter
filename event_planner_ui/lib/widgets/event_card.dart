import 'package:flutter/material.dart';

import '../data/sample_events.dart';
import '../utils/date_label.dart';

/// Carte d'événement : vignette carrée + bloc titre/lieu/date/jauge.
///
/// Le bloc textuel est placé dans un [Expanded] pour occuper tout l'espace
/// restant à droite de la vignette, quelle que soit la largeur de la carte :
/// c'est ce qui empêche un titre long de pousser la vignette hors de vue.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    // Taux de remplissage borné à 1.0, même si registered > capacity
    // (liste d'attente). Converti en flex entiers pour piloter la largeur
    // de la jauge sans jamais dépasser sa piste (voir _CapacityGauge).
    final double ratio = event.capacity <= 0
        ? 1.0
        : (event.registered / event.capacity).clamp(0.0, 1.0);
    final int filledFlex = (ratio * 1000).round().clamp(0, 1000);
    final int remainingFlex = 1000 - filledFlex;
    final Color gaugeColor = event.isSoldOut ? Colors.redAccent : Colors.teal;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                _CapacityGauge(
                  filledFlex: filledFlex,
                  remainingFlex: remainingFlex,
                  color: gaugeColor,
                ),
              ],
            ),
          ),
        ],
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

/// Jauge de places : un [Container] "piste" pleine largeur, superposé dans un
/// [Stack] à une [Row] de deux zones [Expanded] dont les flex reflètent le
/// taux de remplissage. Le flex-based sizing garantit par construction que la
/// barre de remplissage ne peut jamais dépasser la largeur de sa piste, y
/// compris quand registered > capacity (ratio déjà clampé à 1.0 en amont).
class _CapacityGauge extends StatelessWidget {
  const _CapacityGauge({
    required this.filledFlex,
    required this.remainingFlex,
    required this.color,
  });

  final int filledFlex;
  final int remainingFlex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Row(
          children: [
            if (filledFlex > 0)
              Expanded(
                flex: filledFlex,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            if (remainingFlex > 0)
              Expanded(flex: remainingFlex, child: const SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}
