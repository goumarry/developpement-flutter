import 'package:flutter/material.dart';

import '../../domain/rules/capacity_rule.dart';
import '../theme/app_theme.dart';

/// Jauge de remplissage d'un événement.
///
/// * La barre est une fraction de sa piste (`AnimatedFractionallySizedBox`) :
///   elle ne peut pas déborder, quelle que soit la largeur disponible.
/// * Animations implicites : la largeur et la couleur s'animent d'elles-mêmes
///   quand [taken] change (inscription ajoutée, retirée).
/// * Accessibilité : la couleur n'est jamais le seul signal — un libellé
///   (« Complet », « 12 / 40 places ») l'accompagne, et un lecteur d'écran
///   reçoit une phrase complète.
class CapacityGauge extends StatelessWidget {
  const CapacityGauge({super.key, required this.taken, required this.capacity});

  final int taken;
  final int capacity;

  static const Duration _duration = Duration(milliseconds: 400);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull =
        CapacityRule.remaining(capacity: capacity, taken: taken) == 0;
    final ratio = capacity <= 0 ? 1.0 : (taken / capacity).clamp(0.0, 1.0);
    final color = isFull
        ? theme.colorScheme.error
        : ratio >= 0.8
        ? theme.colorScheme.tertiary
        : AppStatusColors.of(context).success;
    final label = isFull ? 'Complet' : '$taken / $capacity places';

    return Semantics(
      label: 'Remplissage',
      value: isFull
          ? 'Complet, $capacity places sur $capacity'
          : '$taken places prises sur $capacity',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                width: double.infinity,
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: AnimatedFractionallySizedBox(
                    duration: _duration,
                    curve: Curves.easeOut,
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: ratio,
                    heightFactor: 1,
                    child: AnimatedContainer(duration: _duration, color: color),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isFull ? theme.colorScheme.error : null,
                fontWeight: isFull ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
