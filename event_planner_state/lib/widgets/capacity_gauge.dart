import 'package:flutter/material.dart';

/// Jauge de remplissage (reprise du fil rouge, TP 2).
///
/// Piste grise pleine largeur surmontée d'une [Row] de deux [Expanded] dont les
/// `flex` reflètent le ratio : la barre ne peut jamais déborder de sa piste.
class CapacityGauge extends StatelessWidget {
  const CapacityGauge({
    super.key,
    required this.ratio,
    this.height = 8,
    this.danger = false,
  });

  /// Taux de remplissage, ramené à [0, 1].
  final double ratio;
  final double height;

  /// Colore la barre en rouge (événement complet / quasi complet).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final clamped = ratio.clamp(0.0, 1.0);
    final filledFlex = (clamped * 1000).round().clamp(0, 1000);
    final remainingFlex = 1000 - filledFlex;
    final color = danger ? Colors.redAccent : Colors.teal;

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
