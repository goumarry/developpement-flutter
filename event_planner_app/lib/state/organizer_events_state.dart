import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/failures.dart';
import '../domain/models/event.dart';
import '../domain/repositories/organizer_event_repository.dart';
import 'action_result.dart';

enum OrganizerStatus { signedOut, loading, loaded, error }

/// Événements de l'organisateur connecté, suivis en temps réel.
class OrganizerEventsState extends ChangeNotifier {
  OrganizerEventsState({required this._repository});

  final OrganizerEventRepository _repository;

  OrganizerStatus _status = OrganizerStatus.signedOut;
  List<Event> _events = const [];
  String? _errorMessage;
  String? _userId;
  StreamSubscription<List<Event>>? _subscription;

  OrganizerStatus get status => _status;
  List<Event> get events => _events;
  String? get errorMessage => _errorMessage;

  /// Suit l'utilisateur connecté : à chaque changement de compte, l'ancien
  /// abonnement est annulé et la liste vidée **avant** d'écouter le nouveau —
  /// les événements d'un compte ne restent jamais affichés pour un autre.
  void bindUser(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _events = const [];
    _errorMessage = null;
    if (userId == null) {
      _status = OrganizerStatus.signedOut;
    } else {
      _status = OrganizerStatus.loading;
      _listen(userId);
    }
    notifyListeners();
  }

  /// Relance l'écoute après une erreur (bouton « Réessayer »).
  void retry() {
    final userId = _userId;
    if (userId == null) return;
    unawaited(_subscription?.cancel());
    _status = OrganizerStatus.loading;
    _errorMessage = null;
    notifyListeners();
    _listen(userId);
  }

  void _listen(String userId) {
    _subscription = _repository
        .watchOwnEvents(userId)
        .listen(
          (events) {
            _events = List.unmodifiable(events);
            _status = OrganizerStatus.loaded;
            notifyListeners();
          },
          onError: (Object error) {
            _errorMessage = error is AppFailure
                ? error.message
                : const UnknownFailure().message;
            _status = OrganizerStatus.error;
            notifyListeners();
          },
        );
  }

  /// Crée l'événement (identifiant vide) ou le met à jour. Le propriétaire
  /// est toujours l'utilisateur connecté, quoi que contienne [event].
  Future<ActionResult> save(Event event) async {
    final userId = _userId;
    if (userId == null) {
      return const ActionResult.failure(
        'Connectez-vous pour enregistrer un événement.',
      );
    }
    final owned = event.copyWith(ownerId: userId);
    try {
      final status = owned.id.isEmpty
          ? await _repository.create(owned)
          : await _repository.update(owned);
      return ActionResult.fromWrite(status);
    } on AppFailure catch (failure) {
      return ActionResult.fromFailure(failure);
    }
  }

  Future<ActionResult> delete(String eventId) async {
    try {
      return ActionResult.fromWrite(await _repository.delete(eventId));
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
