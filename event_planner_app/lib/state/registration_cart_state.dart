import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/failures.dart';
import '../domain/models/event.dart';
import '../domain/models/registration.dart';
import '../domain/repositories/registration_repository.dart';
import '../domain/rules/capacity_rule.dart';
import 'action_result.dart';

/// Issue d'une opération sur le panier : l'appelant sait exactement pourquoi
/// une opération a été refusée, sans exception.
enum CartOutcome {
  added,
  removed,
  rejectedFull,
  rejectedNotEnoughSeats,
  rejectedDuplicate,
  rejectedInvalidSeats,
  rejectedNotFound;

  bool get isSuccess => this == added || this == removed;
}

/// Inscriptions **en cours** (panier, modifiable avant confirmation) et
/// inscriptions **confirmées** de l'utilisateur connecté.
///
/// Les deux contraintes métier sont vérifiées ici, pas dans les écrans :
///  1. capacité — déléguée à [CapacityRule], en comptant les places de la
///     source, celles déjà confirmées par l'utilisateur et celles du panier ;
///  2. doublon — une même personne (courriel normalisé) ne peut figurer
///     qu'une fois par événement, panier et confirmées confondus.
///
/// Une opération refusée **ne notifie pas** : rien n'a changé.
class RegistrationCartState extends ChangeNotifier {
  RegistrationCartState({required this._repository});

  final RegistrationRepository _repository;

  final List<Registration> _lines = [];
  List<Registration> _confirmed = const [];
  String? _userId;
  String? _confirmedError;
  bool _isConfirming = false;
  StreamSubscription<List<Registration>>? _subscription;

  /// Lignes du panier. Vue non modifiable : aucun écran ne peut muter la liste.
  List<Registration> get lines => List.unmodifiable(_lines);

  /// Inscriptions confirmées de l'utilisateur connecté.
  List<Registration> get confirmed => _confirmed;

  /// Erreur de lecture des inscriptions confirmées, ou `null`.
  String? get confirmedError => _confirmedError;

  bool get isEmpty => _lines.isEmpty;
  bool get isConfirming => _isConfirming;

  /// Nombre de places du panier (pastille de l'onglet).
  int get pendingSeats => _lines.fold(0, (sum, line) => sum + line.seats);

  /// Places de l'utilisateur sur un événement, panier + confirmées.
  int heldSeats(String eventId) {
    var seats = 0;
    for (final registration in [..._lines, ..._confirmed]) {
      if (registration.eventId == eventId) seats += registration.seats;
    }
    return seats;
  }

  /// Places encore disponibles pour [event], une fois déduites celles de
  /// l'utilisateur.
  int remainingSeats(Event event) => CapacityRule.remaining(
    capacity: event.capacity,
    taken: event.registered + heldSeats(event.id),
  );

  /// Ajoute une inscription au panier, si les règles métier l'acceptent.
  CartOutcome add({
    required Event event,
    required String participantName,
    required String participantEmail,
    required int seats,
  }) {
    final candidate = Registration(
      eventId: event.id,
      eventTitle: event.title,
      participantName: participantName.trim(),
      participantEmail: participantEmail.trim(),
      seats: seats,
    );
    if ([..._lines, ..._confirmed].any(candidate.isDuplicateOf)) {
      return CartOutcome.rejectedDuplicate;
    }
    final decision = CapacityRule.check(
      capacity: event.capacity,
      taken: event.registered + heldSeats(event.id),
      requestedSeats: seats,
    );
    switch (decision) {
      case CapacityDecision.rejectedInvalidSeats:
        return CartOutcome.rejectedInvalidSeats;
      case CapacityDecision.rejectedFull:
        return CartOutcome.rejectedFull;
      case CapacityDecision.rejectedNotEnoughSeats:
        return CartOutcome.rejectedNotEnoughSeats;
      case CapacityDecision.accepted:
        _lines.add(candidate);
        notifyListeners();
        return CartOutcome.added;
    }
  }

  /// Retire une ligne du panier (avant confirmation).
  CartOutcome remove(Registration line) {
    if (!_lines.remove(line)) return CartOutcome.rejectedNotFound;
    notifyListeners();
    return CartOutcome.removed;
  }

  /// Suit l'utilisateur connecté : (ré)abonne aux inscriptions confirmées de
  /// [userId], ou vide tout à la déconnexion (le panier d'un compte ne doit
  /// pas passer au suivant).
  void bindUser(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _confirmed = const [];
    _confirmedError = null;
    if (userId == null) {
      _lines.clear();
    } else {
      _subscription = _repository
          .watchConfirmed(userId)
          .listen(
            (registrations) {
              _confirmed = List.unmodifiable(registrations);
              _confirmedError = null;
              notifyListeners();
            },
            onError: (Object error) {
              _confirmedError = error is AppFailure
                  ? error.message
                  : const UnknownFailure().message;
              notifyListeners();
            },
          );
    }
    notifyListeners();
  }

  /// Confirmation finale : enregistre tout le panier, puis le vide.
  Future<ActionResult> confirm() async {
    final userId = _userId;
    if (userId == null) {
      return const ActionResult.failure(
        'Connectez-vous pour confirmer vos inscriptions.',
      );
    }
    if (_lines.isEmpty || _isConfirming) {
      return const ActionResult.failure('Aucune inscription à confirmer.');
    }
    _isConfirming = true;
    notifyListeners();
    ActionResult result;
    try {
      final status = await _repository.confirmAll([
        for (final line in _lines) line.copyWith(userId: userId),
      ]);
      _lines.clear();
      result = ActionResult.fromWrite(status);
    } on AppFailure catch (failure) {
      result = ActionResult.fromFailure(failure);
    }
    _isConfirming = false;
    notifyListeners();
    return result;
  }

  /// Annule une inscription déjà confirmée.
  Future<ActionResult> cancelConfirmed(Registration registration) async {
    try {
      return ActionResult.fromWrite(await _repository.cancel(registration.id));
    } on AppFailure catch (failure) {
      return ActionResult.fromFailure(failure);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
