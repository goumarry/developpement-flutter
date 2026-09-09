import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/formule.dart';

/// Écran de confirmation, atteint **uniquement** après le choix d'une formule
/// (valeur non nulle), via `Navigator.pushReplacementNamed` depuis le détail.
///
/// Comme le détail a été *remplacé*, le retour matériel depuis cet écran ne
/// ramène ni sur la sélection ni sur le détail, mais sur l'écran qui précédait
/// le détail : le mur d'événements.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({
    super.key,
    required this.event,
    required this.formule,
  });

  final Event event;
  final Formule formule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.check_circle_outline,
              size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Réservation enregistrée', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 24),
          _RecapRow(label: 'Événement', value: event.title),
          _RecapRow(label: 'Formule', value: formule.label),
          _RecapRow(label: 'Tarif', value: formule.priceLabel),
          const SizedBox(height: 32),
          FilledButton(
            // popUntil plutôt que pushAndRemoveUntil : le mur d'événements est
            // encore au fond de la pile (jamais retiré), on se contente donc de
            // dépiler jusqu'à lui sans le reconstruire. Voir README.
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  const _RecapRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
