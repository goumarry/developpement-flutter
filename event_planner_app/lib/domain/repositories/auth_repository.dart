import '../models/user_profile.dart';

/// Authentification. Les échecs sortent en `AuthFailure` / `NetworkFailure`,
/// avec un message déjà traduit.
abstract class AuthRepository {
  /// Émet l'utilisateur courant à l'abonnement (session restaurée ou `null`),
  /// puis à chaque connexion / déconnexion / expiration de session.
  Stream<UserProfile?> authStateChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> register({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
