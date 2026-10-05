import 'package:flutter/foundation.dart';

import '../models/event.dart';
import '../models/session.dart';

/// Résultat d'une opération sur le panier. « Signal exploitable » exigé par
/// l'énoncé : l'appelant sait exactement pourquoi une opération a été refusée,
/// sans `print` ni exception.
enum CartOutcome {
  added,
  updated,
  removed,
  rejectedDuplicate,
  rejectedEventFull,
  rejectedUserCap,
  rejectedInvalidSeats,
  rejectedNotFound;

  bool get isSuccess =>
      this == added || this == updated || this == removed;
}

/// Une ligne du panier : un événement, la session choisie, un nombre de places.
@immutable
class CartLine {
  const CartLine({
    required this.event,
    required this.session,
    required this.seats,
  });

  final Event event;
  final Session session;
  final int seats;

  CartLine copyWith({Session? session, int? seats}) => CartLine(
        event: event,
        session: session ?? this.session,
        seats: seats ?? this.seats,
      );
}

/// État global du panier d'inscriptions.
///
/// **Découplage strict** : ce fichier n'importe que `package:flutter/foundation.dart`
/// (pour [ChangeNotifier] / [@immutable]) et des modèles Dart purs. Aucun import
/// de `material.dart` / `widgets.dart`.
///
/// Les trois contraintes métier sont vérifiées **ici**, pas dans les écrans :
///  1. un même événement ne peut pas figurer deux fois dans le panier — choix
///     retenu : l'ajout est **refusé** ([CartOutcome.rejectedDuplicate]), la
///     modification passe par [updateSeats] / [changeSession] ;
///  2. l'ajout est refusé si l'événement serait complet
///     (`places prises + places réservées > capacité`) ;
///  3. le total de places réservées, tous événements confondus, ne peut pas
///     dépasser [maxSeatsPerUser].
class RegistrationCart extends ChangeNotifier {
  /// Plafond de places par utilisateur. Choix : un particulier réserve pour
  /// lui-même et quelques accompagnants ; 6 couvre ce cas sans permettre de
  /// bloquer des lots entiers de places sur un événement.
  static const int maxSeatsPerUser = 6;

  final List<CartLine> _lines = [];

  /// Vue non modifiable du panier (aucun écran ne peut muter la liste).
  List<CartLine> get lines => List.unmodifiable(_lines);

  /// Total de places réservées, toutes lignes confondues.
  int get totalSeats => _lines.fold(0, (sum, l) => sum + l.seats);

  /// Nombre d'événements distincts dans le panier (1 ligne max par événement).
  int get distinctEventCount => _lines.length;

  bool get isEmpty => _lines.isEmpty;

  bool containsEvent(String eventId) =>
      _lines.any((l) => l.event.id == eventId);

  CartLine? lineForEvent(String eventId) {
    for (final l in _lines) {
      if (l.event.id == eventId) return l;
    }
    return null;
  }

  /// Places réservées pour un événement donné (0 s'il n'est pas au panier).
  int seatsForEvent(String eventId) => lineForEvent(eventId)?.seats ?? 0;

  /// Ajoute une inscription. Voir les règles métier dans la doc de la classe.
  CartOutcome addRegistration({
    required Event event,
    required Session session,
    int seats = 1,
  }) {
    if (seats < 1) return CartOutcome.rejectedInvalidSeats;
    if (containsEvent(event.id)) return CartOutcome.rejectedDuplicate;
    if (event.taken + seats > event.capacity) {
      return CartOutcome.rejectedEventFull;
    }
    if (totalSeats + seats > maxSeatsPerUser) {
      return CartOutcome.rejectedUserCap;
    }
    _lines.add(CartLine(event: event, session: session, seats: seats));
    notifyListeners();
    return CartOutcome.added;
  }

  /// Modifie le nombre de places d'une inscription existante.
  CartOutcome updateSeats(String eventId, int seats) {
    final i = _lines.indexWhere((l) => l.event.id == eventId);
    if (i < 0) return CartOutcome.rejectedNotFound;
    if (seats < 1) return CartOutcome.rejectedInvalidSeats;

    final line = _lines[i];
    if (line.event.taken + seats > line.event.capacity) {
      return CartOutcome.rejectedEventFull;
    }
    if (totalSeats - line.seats + seats > maxSeatsPerUser) {
      return CartOutcome.rejectedUserCap;
    }
    _lines[i] = line.copyWith(seats: seats);
    notifyListeners();
    return CartOutcome.updated;
  }

  /// Change la session choisie pour une inscription existante.
  CartOutcome changeSession(String eventId, Session session) {
    final i = _lines.indexWhere((l) => l.event.id == eventId);
    if (i < 0) return CartOutcome.rejectedNotFound;
    _lines[i] = _lines[i].copyWith(session: session);
    notifyListeners();
    return CartOutcome.updated;
  }

  /// Retire l'inscription d'un événement.
  CartOutcome removeRegistration(String eventId) {
    final before = _lines.length;
    _lines.removeWhere((l) => l.event.id == eventId);
    if (_lines.length == before) return CartOutcome.rejectedNotFound;
    notifyListeners();
    return CartOutcome.removed;
  }

  void clear() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }
}
