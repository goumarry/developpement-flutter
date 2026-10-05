import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Niveau 2 de la hiérarchie de la Partie A, conservé pour la Partie B.
///
/// Après le passage à Provider (A.3), ce widget **ne reçoit plus ni le
/// compteur ni un callback** : il ne dépend d'aucun état applicatif. Il se
/// contente de titrer une section et de disposer ses enfants. Conséquence
/// mesurée : il n'est plus reconstruit lors d'une mutation du panier.
class EventSection extends StatelessWidget {
  const EventSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Compteur de recompositions (mesure Partie A). Voir README.
  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    if (kDebugMode) debugPrint('BUILD EventSection (#$builds)');

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}
