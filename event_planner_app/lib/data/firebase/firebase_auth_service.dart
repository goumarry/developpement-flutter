import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/failures.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

/// Authentification par courriel et mot de passe sur Firebase Auth.
class FirebaseAuthService implements AuthRepository {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<UserProfile?> authStateChanges() {
    return _auth.authStateChanges().map(
      (user) => user == null
          ? null
          : UserProfile(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName,
            ),
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(
      () => _auth.signInWithEmailAndPassword(email: email, password: password),
    );
  }

  @override
  Future<void> register({required String email, required String password}) {
    return _guard(
      () => _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  Future<void> _guard(Future<Object?> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw _failureFor(error.code);
    } on Exception {
      throw const UnknownFailure();
    }
  }

  /// Un message par code ; tout code inconnu retombe sur un message
  /// générique, jamais sur `e.message`.
  static AppFailure _failureFor(String code) {
    switch (code) {
      case 'email-already-in-use':
        return const AuthFailure(
          'Un compte existe déjà avec cette adresse. Connectez-vous ou '
          'réinitialisez votre mot de passe.',
        );
      case 'invalid-email':
        return const AuthFailure(
          "Cette adresse courriel n'est pas valide (exemple : prenom@domaine.fr).",
        );
      case 'weak-password':
        return const AuthFailure(
          'Mot de passe trop faible : choisissez au moins 6 caractères.',
        );
      // Mauvais mot de passe et compte inexistant donnent le même code sur
      // un projet récent, et volontairement le même message : ne pas révéler
      // si un compte existe.
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return const AuthFailure('Adresse courriel ou mot de passe incorrect.');
      case 'too-many-requests':
        return const AuthFailure(
          'Trop de tentatives. Patientez quelques minutes avant de réessayer.',
        );
      case 'operation-not-allowed':
        return const AuthFailure(
          "La connexion par courriel et mot de passe n'est pas activée pour "
          'cette application.',
        );
      case 'user-disabled':
        return const AuthFailure('Ce compte a été désactivé.');
      case 'network-request-failed':
        return const NetworkFailure();
      default:
        return const UnknownFailure();
    }
  }
}
