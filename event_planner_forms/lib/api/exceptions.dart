/// Hiérarchie d'exceptions applicatives de la couche réseau.
///
/// Chaque sous-type correspond à une cause distincte et porte un message
/// déjà destiné à l'affichage (en français, sans trace Dart brute). Le type
/// réel de l'exception pilote aussi la politique de nouvelle tentative dans
/// `UsersApi` : voir le README, partie C.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Panne de connexion (pas de réseau, DNS, connexion refusée...).
/// Erreur transitoire : éligible à une nouvelle tentative.
class NetworkException extends ApiException {
  const NetworkException(super.message);
}

/// Le délai (`.timeout`) a été dépassé avant réponse du serveur.
/// Nommée différemment de `dart:async`'s `TimeoutException` pour éviter tout
/// conflit d'import. Erreur transitoire : éligible à une nouvelle tentative.
class RequestTimeoutException extends ApiException {
  const RequestTimeoutException(super.message);
}

/// Code HTTP >= 500 (ou tout autre code inattendu non couvert ci-dessous).
/// Transitoire uniquement si [statusCode] est un 5xx — voir `UsersApi._withRetry`.
class ServerException extends ApiException {
  const ServerException(super.message, this.statusCode);

  final int statusCode;
}

/// Code HTTP 404 : la ressource demandée n'existe pas. Jamais transitoire,
/// jamais rejouée automatiquement.
class NotFoundException extends ApiException {
  const NotFoundException(super.message);
}

/// Le corps de la réponse n'a pas pu être interprété comme le JSON attendu
/// (JSON invalide, structure inattendue). Rejouer la requête identique ne
/// changera rien : jamais rejouée automatiquement.
class DecodingException extends ApiException {
  const DecodingException(super.message);
}
