/// Échecs applicatifs, communs à toutes les couches — **Dart pur**.
///
/// Les implémentations de `data/` traduisent leurs exceptions techniques
/// (`http.ClientException`, `FirebaseException`, `FormatException`…) en l'un
/// de ces types. Les couches `state/` et `presentation/` ne connaissent donc
/// ni `http` ni Firebase : elles ne manipulent que des [AppFailure], dont le
/// [message] est déjà rédigé pour l'utilisateur (jamais une trace Dart brute).
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Pas de réseau, DNS, connexion refusée… Transitoire.
class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message =
        'Connexion impossible. Vérifiez votre réseau puis réessayez.',
  ]);
}

/// Le serveur n'a pas répondu dans le délai imparti. Transitoire.
class TimeoutFailure extends AppFailure {
  const TimeoutFailure([
    super.message = 'Le serveur met trop de temps à répondre. Réessayez.',
  ]);
}

/// Code HTTP inattendu (5xx notamment).
class ServerFailure extends AppFailure {
  const ServerFailure(this.statusCode, [String? message])
    : super(
        message ??
            'Le service est momentanément indisponible (code $statusCode).',
      );

  final int statusCode;
}

/// La ressource demandée n'existe pas (HTTP 404, document absent).
class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Cet élément est introuvable.']);
}

/// Réponse reçue mais illisible (JSON invalide ou de forme inattendue).
class DecodingFailure extends AppFailure {
  const DecodingFailure([
    super.message = 'La réponse du serveur est illisible. Réessayez plus tard.',
  ]);
}

/// Échec d'authentification (identifiants, compte existant, etc.).
class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

/// Refus des règles de sécurité du serveur, ou session absente / expirée.
class PermissionFailure extends AppFailure {
  const PermissionFailure([
    super.message =
        "Accès refusé : vous n'avez pas le droit d'effectuer cette opération.",
  ]);
}

/// Tout le reste : message générique, jamais le détail technique.
class UnknownFailure extends AppFailure {
  const UnknownFailure([
    super.message =
        'Une erreur est survenue. Veuillez réessayer dans un instant.',
  ]);
}
