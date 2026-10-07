import 'package:flutter/material.dart';

/// Rangée de filtres décoratifs (pas de comportement au tap). Repris du TP 3,
/// utilisé par le mur d'événements (TP 2/3) — à ne pas confondre avec les
/// `FilterChip` fonctionnels de l'écran liste Provider (TP 4).
class CategoryFilters extends StatelessWidget {
  const CategoryFilters({super.key, required this.categories});

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final category in categories) _FilterPill(label: category)],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.teal, fontWeight: FontWeight.w600),
      ),
    );
  }
}
