import 'package:flutter/material.dart';

import '../models/event.dart';

/// Vignette d'événement (reprise du fil rouge TP 2/3). Image de démonstration
/// avec repli si le chargement échoue.
class EventThumb extends StatelessWidget {
  const EventThumb({super.key, required this.event, this.size = 64});

  final Event event;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: event.imageUrl.isEmpty
            ? _fallback()
            : Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.event, color: Colors.black38),
      );
}
