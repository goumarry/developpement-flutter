import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Section titrée de la liste d'événements (TP 4). Ne dépend d'aucun état
/// applicatif — il n'est donc jamais reconstruit lors d'une mutation du
/// panier, seules la tuile concernée et le badge le sont.
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

  /// Compteur de recompositions (mesure Partie A, TP 4). Voir README.
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
