import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../models/session.dart';
import '../state/registration_cart.dart';
import '../utils/cart_feedback.dart';
import '../utils/date_label.dart';
import '../widgets/capacity_gauge.dart';
import '../widgets/cart_badge.dart';
import '../widgets/event_thumb.dart';

/// Détail d'un événement et de ses sessions.
///
/// - État **local** (session choisie, nombre de places du sélecteur) : `setState`.
/// - État **global** (le panier) : lu via `context.select` (juste ce qui est
///   affiché) et muté via `context.read<RegistrationCart>()` — jamais un setter.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.event});

  final Event event;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Session _selectedSession =
      widget.event.sessions.isNotEmpty ? widget.event.sessions.first : _noSession;
  int _seats = 1;

  static const _noSession =
      Session(id: '-', label: 'Aucune session', schedule: '');

  Event get event => widget.event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final seatsInCart = context.select<RegistrationCart, int>(
      (cart) => cart.seatsForEvent(event.id),
    );
    final alreadyInCart = seatsInCart > 0;
    final projectedTaken = event.taken + seatsInCart;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail'),
        actions: const [CartBadge()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: EventThumb(event: event, size: 140)),
          const SizedBox(height: 16),
          Text(event.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '${event.category} · ${dateLabel(event.date)}',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            '${event.remainingSeats} places restantes sur ${event.capacity}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          CapacityGauge(
            ratio: event.capacity == 0 ? 1 : projectedTaken / event.capacity,
            height: 10,
            danger: projectedTaken >= event.capacity,
          ),
          const SizedBox(height: 24),

          if (alreadyInCart)
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text('Déjà dans le panier : $seatsInCart place(s)'),
                subtitle: const Text(
                  'Modifiez la quantité ou la session depuis le panier.',
                ),
              ),
            )
          else ...[
            Text('Choisir une session', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final session in event.sessions)
              Card(
                margin: const EdgeInsets.only(bottom: 6),
                color: _selectedSession.id == session.id
                    ? theme.colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  dense: true,
                  onTap: () => setState(() => _selectedSession = session),
                  leading: Icon(
                    _selectedSession.id == session.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(session.label),
                  subtitle: Text(session.schedule),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Places', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton.outlined(
                  onPressed:
                      _seats > 1 ? () => setState(() => _seats--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('$_seats', style: theme.textTheme.titleLarge),
                ),
                IconButton.outlined(
                  onPressed: _seats < RegistrationCart.maxSeatsPerUser
                      ? () => setState(() => _seats++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('Ajouter au panier ($_seats place(s))'),
              onPressed: event.sessions.isEmpty ? null : _addToCart,
            ),
          ],
        ],
      ),
    );
  }

  void _addToCart() {
    final outcome = context.read<RegistrationCart>().addRegistration(
          event: event,
          session: _selectedSession,
          seats: _seats,
        );
    showCartOutcome(context, outcome);
  }
}
