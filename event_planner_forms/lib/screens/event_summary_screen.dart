import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event_draft.dart';

/// Récapitulatif en lecture seule de l'événement en cours de création (TP 6,
/// partie B) — aucun champ éditable ici : toute correction repasse par
/// « Modifier », qui dépile cet écran sans perdre la saisie du formulaire
/// (ses contrôleurs ne sont jamais recréés, l'écran était seulement poussé
/// par-dessus).
class EventSummaryScreen extends StatelessWidget {
  const EventSummaryScreen({super.key, required this.draft});

  final EventDraft draft;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMEd('fr_FR');

    return Scaffold(
      appBar: AppBar(title: const Text('Récapitulatif')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Row(label: 'Titre', value: draft.title),
          _Row(label: 'Description', value: draft.description),
          _Row(label: 'Catégorie', value: draft.category),
          _Row(label: 'Capacité', value: '${draft.capacity} places'),
          _Row(
            label: 'Lieu',
            value: draft.isOnline
                ? 'En ligne'
                : (draft.address?.isNotEmpty == true
                    ? draft.address!
                    : 'Non renseigné'),
          ),
          _Row(
            label: 'Dates',
            value: '${dateFormat.format(draft.startDate)} → '
                '${dateFormat.format(draft.endDate)}',
          ),
          _Row(label: 'Heure de début', value: draft.startTime.format(context)),
          _Row(
            label: 'Tarif',
            value: draft.isFree
                ? 'Gratuit'
                : '${draft.price.toStringAsFixed(2)} €',
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmer'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
