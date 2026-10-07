import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../routes/app_routes.dart';
import '../state/display_preferences.dart';
import '../state/registration_cart.dart';
import '../utils/cart_feedback.dart';
import '../utils/date_label.dart';
import 'capacity_gauge.dart';
import 'event_thumb.dart';

/// Ligne d'événement de l'écran liste Provider (TP 4).
///
/// Consommation d'état **ciblée** :
///  - `context.select` sur le nombre de places réservées **pour cet événement**
///    seulement : ajouter au panier un autre événement ne reconstruit pas cette
///    tuile ;
///  - `context.select` sur la densité d'affichage ;
///  - `context.read` (jamais dans `build`) pour muter le panier.
class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event});

  final Event event;

  /// Compteur de recompositions, toutes instances confondues (mesure Partie A).
  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;

    final seatsInCart = context.select<RegistrationCart, int>(
      (cart) => cart.seatsForEvent(event.id),
    );
    final density = context.select<DisplayPreferences, EventDensity>(
      (prefs) => prefs.density,
    );
    if (kDebugMode) {
      debugPrint('BUILD EventTile ${event.id} (#$builds) seatsInCart=$seatsInCart');
    }

    final compact = density == EventDensity.compact;
    final projectedTaken = event.taken + seatsInCart;
    final full = projectedTaken >= event.capacity;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 3 : 7,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context)
              .pushNamed(AppRoutes.eventDetail, arguments: event.id),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventThumb(event: event, size: compact ? 44 : 64),
                SizedBox(width: compact ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              maxLines: compact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: compact ? 13 : 15,
                              ),
                            ),
                          ),
                          if (seatsInCart > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Tooltip(
                                message: '$seatsInCart place(s) au panier',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.shopping_cart, size: 13),
                                      const SizedBox(width: 3),
                                      Text('$seatsInCart',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (!compact) const SizedBox(height: 4),
                      Text(
                        '${event.category} · ${dateLabel(event.date)} · '
                        '${event.remainingSeats} places restantes',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 8),
                        CapacityGauge(
                          ratio: event.capacity == 0
                              ? 1
                              : projectedTaken / event.capacity,
                          danger: full,
                        ),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Ajouter 1 place'),
                          onPressed: event.sessions.isEmpty
                              ? null
                              : () => _quickAdd(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _quickAdd(BuildContext context) {
    final outcome = context.read<RegistrationCart>().addRegistration(
          event: event,
          session: event.sessions.first,
          seats: 1,
        );
    showCartOutcome(context, outcome);
  }
}
