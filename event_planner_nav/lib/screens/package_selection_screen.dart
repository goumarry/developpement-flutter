import 'package:flutter/material.dart';

import '../data/sample_packages.dart';
import '../models/formule.dart';

/// Écran de sélection d'une formule de participation.
///
/// Ne pousse **aucun** nouvel écran : il renvoie sa sélection à l'écran de
/// détail via `Navigator.pop(context, formuleChoisie)`.
///
/// Un [PopScope] intercepte toute tentative de retour *matérielle ou
/// applicative* (bouton système, flèche de l'AppBar) et demande confirmation
/// avant de laisser la navigation se poursuivre. Le choix explicite d'une
/// formule, lui, appelle directement `Navigator.pop(formule)` : c'est une
/// action volontaire, elle n'a pas à passer par le dialogue d'abandon.
class PackageSelectionScreen extends StatelessWidget {
  const PackageSelectionScreen({super.key, required this.eventTitle});

  final String eventTitle;

  @override
  Widget build(BuildContext context) {
    return PopScope<Formule>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final NavigatorState navigator = Navigator.of(context);
        final bool abandon = await _confirmAbandon(context);
        if (abandon && context.mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Choisir une formule')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Formule de participation pour :\n$eventTitle',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            for (final formule in samplePackages)
              _FormuleCard(
                formule: formule,
                onSelected: () => Navigator.of(context).pop(formule),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmAbandon(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abandonner la sélection en cours ?'),
        content: const Text(
          'Vous reviendrez au détail de l\'événement sans avoir choisi de '
          'formule.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continuer la sélection'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
    // null (dialogue fermé par tap hors cadre) == on ne navigue pas.
    return result ?? false;
  }
}

class _FormuleCard extends StatelessWidget {
  const _FormuleCard({required this.formule, required this.onSelected});

  final Formule formule;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(formule.label, style: theme.textTheme.titleLarge),
                  ),
                  Text(formule.priceLabel, style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 6),
              Text(formule.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: onSelected,
                  child: const Text('Choisir cette formule'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
