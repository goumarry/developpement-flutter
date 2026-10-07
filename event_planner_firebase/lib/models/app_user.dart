import 'package:firebase_auth/firebase_auth.dart';

/// Vue minimale et immuable de l'utilisateur connecté : l'interface ne
/// manipule pas directement `User` (type du SDK, mutable). Ce n'est **pas** un
/// état global : on le recrée à partir de `authStateChanges()` /
/// `userChanges()` là où on en a besoin.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.emailVerified,
  });

  factory AppUser.fromFirebase(User user) => AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        emailVerified: user.emailVerified,
      );

  final String uid;
  final String email;
  final String? displayName;
  final bool emailVerified;

  /// Nom à afficher : le nom de profil s'il existe, sinon le courriel.
  String get label =>
      (displayName != null && displayName!.trim().isNotEmpty)
          ? displayName!
          : email;
}
