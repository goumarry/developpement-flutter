import 'package:flutter/foundation.dart';

import '../models/event.dart';

/// Critère de tri de la liste d'événements.
enum EventSort {
  dateAsc('Date'),
  titleAsc('Titre'),
  seatsLeftDesc('Places restantes');

  const EventSort(this.label);
  final String label;
}

/// Densité d'affichage de la liste (réemploi de la notion du TP 2).
enum EventDensity {
  comfortable('Confortable'),
  compact('Compacte');

  const EventDensity(this.label);
  final String label;
}

/// Préférences d'affichage de la liste d'événements.
///
/// Notifier **totalement indépendant** de `RegistrationCart` : il ne l'importe
/// pas et n'y fait jamais référence. Même contrainte de découplage : seul
/// `package:flutter/foundation.dart` et du Dart pur.
class DisplayPreferences extends ChangeNotifier {
  EventSort _sort = EventSort.dateAsc;
  String? _category; // null == toutes catégories
  EventDensity _density = EventDensity.comfortable;

  EventSort get sort => _sort;

  /// Catégorie filtrée, ou `null` pour tout afficher.
  String? get category => _category;

  EventDensity get density => _density;

  void setSort(EventSort value) {
    if (value == _sort) return;
    _sort = value;
    notifyListeners();
  }

  void setCategory(String? value) {
    if (value == _category) return;
    _category = value;
    notifyListeners();
  }

  /// Sélectionne la catégorie, ou la désélectionne si elle l'était déjà.
  void toggleCategory(String value) =>
      setCategory(_category == value ? null : value);

  void setDensity(EventDensity value) {
    if (value == _density) return;
    _density = value;
    notifyListeners();
  }

  /// Applique filtre puis tri à une liste d'événements.
  ///
  /// **Fonction pure** : ne mute pas [source], renvoie une nouvelle liste.
  List<Event> applyTo(List<Event> source) {
    final filtered = _category == null
        ? [...source]
        : [
            for (final e in source)
              if (e.category == _category) e,
          ];

    switch (_sort) {
      case EventSort.dateAsc:
        filtered.sort((a, b) => a.date.compareTo(b.date));
      case EventSort.titleAsc:
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case EventSort.seatsLeftDesc:
        filtered.sort((a, b) => b.remainingSeats.compareTo(a.remainingSeats));
    }
    return filtered;
  }
}
