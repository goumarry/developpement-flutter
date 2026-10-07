import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../models/formule.dart';
import '../models/session.dart';
import '../routes/app_routes.dart';
import '../routes/route_generator.dart';
import '../state/registration_cart.dart';
import '../utils/cart_feedback.dart';
import '../utils/date_label.dart';
import '../widgets/capacity_gauge.dart';
import '../widgets/cart_badge.dart';
import '../widgets/event_thumb.dart';

/// Détail d'un événement — fusion fil-rouge.
///
/// Deux mécanismes volontairement **distincts et côte à côte**, pour montrer
/// les deux techniques telles qu'apprises :
/// - **Panier Provider (TP 4)** : sélection d'une session + nombre de places,
///   état global muté via `context.read<RegistrationCart>()`.
/// - **Formule par navigation (TP 3)** : bouton secondaire qui pousse l'écran
///   de sélection de formule et attend sa valeur de retour typée
///   (`Future<Formule?>`), avec `PopScope` côté sélection ; un choix non nul
///   remplace cet écran par la confirmation (`pushReplacementNamed`).
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

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Autre parcours (navigation, TP 3)',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            "Indépendant du panier ci-dessus : choisir une formule ouvre un "
            "écran protégé par PopScope, puis remplace ce détail par un "
            "récapitulatif si une formule est retenue.",
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.confirmation_num_outlined),
            label: const Text('Choisir une formule (démo TP 3)'),
            onPressed: () => _chooseFormule(context),
          ),
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

  /// Ouvre l'écran de sélection et **attend sa valeur de retour**, typée
  /// `Future<Formule?>` (TP 3) :
  /// - valeur non nulle -> remplace ce détail par la confirmation
  ///   (`pushReplacementNamed`) ;
  /// - `null` -> l'utilisateur est revenu en arrière sans choisir -> on reste
  ///   sur le détail, intact, avec un simple message.
  Future<void> _chooseFormule(BuildContext context) async {
    final Future<Formule?> selection = Navigator.of(context).pushNamed<Formule>(
      AppRoutes.packageSelection,
      arguments: event.title,
    );
    final Formule? formule = await selection;

    if (!context.mounted) return;

    if (formule == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Sélection annulée — aucune formule choisie.')),
        );
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.confirmation,
      arguments: ConfirmationArgs(event: event, formule: formule),
    );
  }
}
