import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/failures.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/auth_repository.dart';
import 'action_result.dart';

enum AuthStatus {
  /// Le SDK n'a pas encore dit s'il existe une session à restaurer.
  unknown,
  signedOut,
  signedIn,
}

/// Session de l'utilisateur, alimentée par le flux du dépôt
/// d'authentification.
class AuthState extends ChangeNotifier {
  AuthState({required this._repository}) {
    _subscription = _repository.authStateChanges().listen(
      _onUserChanged,
      // Flux en erreur : on se comporte comme « non connecté », le
      // catalogue reste consultable.
      onError: (Object _) => _onUserChanged(null),
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<UserProfile?> _subscription;

  AuthStatus _status = AuthStatus.unknown;
  UserProfile? _user;
  bool _sessionExpired = false;
  bool _signingOut = false;

  AuthStatus get status => _status;
  UserProfile? get user => _user;
  bool get isSignedIn => _user != null;

  /// Vrai si la session a pris fin **sans** que l'utilisateur se déconnecte
  /// lui-même (jeton révoqué, compte désactivé…). Les écrans qui exigent une
  /// identité affichent alors « session expirée » plutôt que « connectez-vous ».
  bool get sessionExpired => _sessionExpired;

  void _onUserChanged(UserProfile? user) {
    if (user == null && _user != null && !_signingOut) _sessionExpired = true;
    if (user != null) _sessionExpired = false;
    _signingOut = false;
    _user = user;
    _status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  Future<ActionResult> signIn({
    required String email,
    required String password,
  }) {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<ActionResult> register({
    required String email,
    required String password,
  }) {
    return _run(() => _repository.register(email: email, password: password));
  }

  Future<ActionResult> sendPasswordReset(String email) =>
      _run(() => _repository.sendPasswordReset(email));

  Future<ActionResult> signOut() async {
    _signingOut = true;
    final result = await _run(_repository.signOut);
    if (!result.isSuccess) _signingOut = false;
    return result;
  }

  Future<ActionResult> _run(Future<void> Function() action) async {
    try {
      await action();
      return const ActionResult.success();
    } on AppFailure catch (failure) {
      return ActionResult.fromFailure(failure);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
