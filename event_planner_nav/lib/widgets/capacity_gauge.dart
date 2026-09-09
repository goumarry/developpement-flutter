import 'package:flutter/material.dart';

import '../models/event.dart';

/// Jauge de places, **extraite telle quelle du TP 2** pour être réutilisée par
/// [EventCard] (le mur) et par l'écran de détail sans dupliquer le calcul.
///
/// Un [Container] "piste" pleine largeur est superposé dans un [Stack] à une
/// [Row] de deux zones [Expanded] dont les `flex` reflètent le taux de
/// remplissage. Comme la somme des `flex` est fixe, la barre de remplissage ne
/// peut structurellement jamais dépasser la largeur de sa piste — y compris
/// quand `registered > capacity` (ratio clampé à 1.0).
class CapacityGauge extends StatelessWidget {
  const CapacityGauge({super.key, required this.event, this.height = 6});

  final Event event;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double ratio = event.capacity <= 0
        ? 1.0
        : (event.registered / event.capacity).clamp(0.0, 1.0);
    final int filledFlex = (ratio * 1000).round().clamp(0, 1000);
    final int remainingFlex = 1000 - filledFlex;
    final Color color = event.isSoldOut ? Colors.redAccent : Colors.teal;

    return Stack(
      children: [
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
        Row(
          children: [
            if (filledFlex > 0)
              Expanded(
                flex: filledFlex,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            if (remainingFlex > 0)
              Expanded(flex: remainingFlex, child: const SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}
