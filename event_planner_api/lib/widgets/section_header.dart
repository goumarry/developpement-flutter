import 'package:flutter/material.dart';

/// Titre de section aligné à gauche + compteur aligné à droite. Repris du
/// TP 2/3.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('$count événements', style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    );
  }
}
