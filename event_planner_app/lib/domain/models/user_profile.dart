/// Vue immuable de l'utilisateur connecté — Dart pur. L'interface ne manipule
/// jamais le type `User` du SDK Firebase (mutable, et réservé à `data/`).
class UserProfile {
  const UserProfile({required this.uid, required this.email, this.displayName});

  final String uid;
  final String email;
  final String? displayName;

  /// Nom à afficher : le nom de profil s'il existe, sinon le courriel.
  String get label {
    final name = displayName?.trim() ?? '';
    return name.isEmpty ? email : name;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          other.uid == uid &&
          other.email == email &&
          other.displayName == displayName;

  @override
  int get hashCode => Object.hash(uid, email, displayName);

  @override
  String toString() => 'UserProfile($uid, $email)';
}
