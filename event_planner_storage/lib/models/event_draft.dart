import 'package:flutter/material.dart' show TimeOfDay;

/// Objet produit par la confirmation du formulaire de création d'événement
/// (TP 6, partie B) — immuable et typé, jamais une `Map<String, dynamic>` ni
/// un ensemble de variables éparses. Les écrans qui le reçoivent (le
/// récapitulatif, le `SnackBar` de confirmation) ne lisent que cette
/// instance, jamais les contrôleurs bruts du formulaire qui l'a produite.
class EventDraft {
  const EventDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.capacity,
    required this.isOnline,
    required this.address, // null si isOnline == true
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.price, // 0 si isFree == true
    required this.isFree,
  });

  final String title;
  final String description;
  final String category;
  final int capacity;
  final bool isOnline;
  final String? address;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final double price;
  final bool isFree;
}
