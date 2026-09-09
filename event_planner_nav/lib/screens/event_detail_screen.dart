import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/formule.dart';
import '../routes/app_routes.dart';
import '../routes/route_generator.dart';
import '../utils/date_label.dart';
import '../widgets/capacity_gauge.dart';

/// Écran de détail d'un événement.
///
/// L'écran reçoit un [Event] **déjà résolu** : la conversion `String id ->
/// Event` est faite en amont, dans [RouteGenerator], à partir du jeu de
/// données du TP 2 (`findEventById`). Aucune donnée n'est recalculée ni
/// récupérée par un autre canal.
class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // La flèche de retour de l'AppBar est ajoutée automatiquement par Flutter
      // dès que le Navigator peut dépiler (canPop == true) : voir README.
      appBar: AppBar(title: const Text('Détail de l\'événement')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(event.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.category_outlined, label: event.category),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.place_outlined,
            label: _locationLabel(event),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.event_outlined,
            label: dateLabel(event.date),
          ),
          const SizedBox(height: 24),
          Text('Places', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          CapacityGauge(event: event, height: 10),
          const SizedBox(height: 8),
          Text(
            event.isSoldOut
                ? 'Complet — ${event.registered}/${event.capacity}'
                : '${event.registered}/${event.capacity} inscrits · '
                    '${event.remainingSeats} places restantes',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.confirmation_num_outlined),
            label: const Text('Choisir une formule'),
            onPressed: () => _chooseFormule(context),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  /// Ouvre l'écran de sélection et **attend sa valeur de retour**.
  ///
  /// Le `Future` est explicitement typé `Future<Formule?>` (aucun `dynamic`) :
  /// - valeur non nulle -> l'utilisateur a choisi -> on remplace l'écran de
  ///   détail par la confirmation (`pushReplacementNamed`) ;
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

  String _locationLabel(Event event) {
    if (event.isOnline) return 'Diffusion en ligne';
    if (event.venue.isEmpty && event.city.isEmpty) return 'Lieu à confirmer';
    if (event.venue.isEmpty) return event.city;
    if (event.city.isEmpty) return event.venue;
    return '${event.venue}, ${event.city}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
      ],
    );
  }
}
