import 'package:flutter/material.dart';

/// Repris du TP 2/3.
class StatItem {
  const StatItem({required this.value, required this.label});

  final String value;
  final String label;
}

/// Barre de statistiques : N zones de largeur strictement égale
/// ([Expanded] sans flex explicite, donc flex=1 partout), séparées par des
/// traits de 1px qui occupent toute la hauteur grâce à
/// `crossAxisAlignment: stretch` sur la [Row] (pas besoin d'IntrinsicHeight).
class StatsBar extends StatelessWidget {
  const StatsBar({super.key, required this.items});

  final List<StatItem> items;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(Container(width: 1, color: Colors.black12));
      }
      children.add(Expanded(child: _StatCell(item: items[i])));
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.item});

  final StatItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.value,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
