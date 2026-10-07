import 'package:cloud_firestore/cloud_firestore.dart';

/// Traduit une erreur Firestore en message utilisateur. `permission-denied`
/// est un cas fonctionnel normal (règles de sécurité serveur), pas un crash.
String translateFirestoreError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return "Accès refusé : vous n'avez pas le droit d'effectuer cette "
            'opération (règles de sécurité du serveur).';
      case 'unavailable':
        return 'Serveur injoignable. Les données locales restent '
            'consultables ; vos modifications seront envoyées au retour de '
            'la connexion.';
      case 'failed-precondition':
        return 'Cette requête nécessite un index Firestore qui n’existe pas '
            'encore.';
      case 'unauthenticated':
        return 'Session expirée : reconnectez-vous.';
      case 'not-found':
        return 'Document introuvable.';
    }
  }
  return 'Une erreur est survenue. Veuillez réessayer dans un instant.';
}

/// `true` si [error] est un refus des règles de sécurité.
bool isPermissionDenied(Object error) =>
    error is FirebaseException && error.code == 'permission-denied';
