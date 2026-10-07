import 'package:firebase_auth/firebase_auth.dart';

/// Message générique : tout code non reconnu retombe ici, jamais sur le
/// contenu brut de l'exception (`e.message` / `e.toString()` interdits).
const String genericAuthErrorMessage =
    'Une erreur est survenue. Veuillez réessayer dans un instant.';

/// Traduit le `code` d'une [FirebaseAuthException] en message français
/// destiné à un utilisateur non technique.
///
/// Fonction pure sur le code (testable sans Firebase) : [translateAuthCode].
String translateAuthError(Object error) {
  if (error is FirebaseAuthException) return translateAuthCode(error.code);
  return genericAuthErrorMessage;
}

String translateAuthCode(String code) {
  switch (code) {
    case 'email-already-in-use':
      return 'Un compte existe déjà avec cette adresse courriel. '
          'Connectez-vous ou réinitialisez votre mot de passe.';
    case 'invalid-email':
      return "Cette adresse courriel n'est pas valide. "
          'Vérifiez-la (exemple : prenom@domaine.fr).';
    case 'weak-password':
      return 'Mot de passe trop faible : choisissez au moins 6 caractères.';
    // Depuis l'« email enumeration protection », Firebase renvoie
    // `invalid-credential` aussi bien pour un mauvais mot de passe que pour
    // un compte inexistant ; `wrong-password` / `user-not-found` subsistent
    // sur d'anciens projets. Même message : ne pas révéler si le compte existe.
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Adresse courriel ou mot de passe incorrect.';
    case 'too-many-requests':
      return 'Trop de tentatives. Patientez quelques minutes avant de '
          'réessayer.';
    case 'operation-not-allowed':
      return "La connexion par courriel et mot de passe n'est pas activée "
          'pour cette application. Contactez le support.';
    case 'network-request-failed':
      return 'Connexion réseau indisponible. Vérifiez votre connexion et '
          'réessayez.';
    case 'requires-recent-login':
      return 'Pour des raisons de sécurité, reconnectez-vous puis réessayez.';
    default:
      return genericAuthErrorMessage;
  }
}
