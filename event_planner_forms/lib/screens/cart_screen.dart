import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/registration_cart.dart';
import '../utils/cart_feedback.dart';

/// Synthèse du panier (TP 4). `context.watch<RegistrationCart>()` : cet écran
/// affiche l'intégralité du panier, il se reconstruit donc à chaque
/// mutation — c'est le comportement voulu ici.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<RegistrationCart>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon panier')),
      body: cart.isEmpty
          ? const Center(child: Text('Votre panier est vide.'))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final line in cart.lines)
                        _CartLineCard(line: line),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cart.totalSeats} place(s) · '
                              '${cart.distinctEventCount} événement(s)',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              'Plafond : ${RegistrationCart.maxSeatsPerUser} places / personne',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.read<RegistrationCart>().clear(),
                        child: const Text('Vider'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<RegistrationCart>();
    final event = line.event;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Retirer',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => showCartOutcome(
                    context,
                    cart.removeRegistration(event.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            PopupMenuButton<String>(
              onSelected: (sessionId) {
                final session =
                    event.sessions.firstWhere((s) => s.id == sessionId);
                showCartOutcome(
                  context,
                  cart.changeSession(event.id, session),
                );
              },
              itemBuilder: (_) => [
                for (final s in event.sessions)
                  PopupMenuItem(value: s.id, child: Text('${s.label} · ${s.schedule}')),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_note, size: 16),
                  const SizedBox(width: 6),
                  Text('${line.session.label} · ${line.session.schedule}'),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Places'),
                const Spacer(),
                IconButton.outlined(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showCartOutcome(
                    context,
                    line.seats <= 1
                        ? cart.removeRegistration(event.id)
                        : cart.updateSeats(event.id, line.seats - 1),
                  ),
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${line.seats}',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton.outlined(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showCartOutcome(
                    context,
                    cart.updateSeats(event.id, line.seats + 1),
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
