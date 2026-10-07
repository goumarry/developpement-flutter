import 'package:flutter/material.dart';

import '../../domain/models/event.dart';

/// Visuel d'un événement, avec repli si l'image est absente ou ne se charge
/// pas (hors connexion notamment : aucune exception, une icône à la place).
///
/// Accessibilité : l'image porte un équivalent textuel ([Image.semanticLabel])
/// et le repli le reprend, pour qu'un lecteur d'écran annonce la même chose
/// dans les deux cas.
class EventImage extends StatelessWidget {
  const EventImage({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final label = 'Visuel de l’événement ${event.title}';
    final scheme = Theme.of(context).colorScheme;
    final fallback = Semantics(
      image: true,
      label: label,
      child: ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            event.isOnline ? Icons.videocam_outlined : Icons.event_outlined,
            size: 32,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
    if (event.imageUrl.isEmpty) return fallback;
    return Image.network(
      event.imageUrl,
      fit: BoxFit.cover,
      semanticLabel: label,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
