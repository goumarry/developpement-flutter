import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:http/http.dart' as http;

import '../models/participant.dart';
import '../models/users_page.dart';
import 'exceptions.dart';

/// Seul point d'accès réseau de l'application : aucun autre fichier ne doit
/// appeler `http.get`/`http.post` directement.
///
/// Porte les exigences de la partie C : une unique instance de [http.Client]
/// réutilisée (et fermée via [close]), un délai d'expiration explicite par
/// requête, une nouvelle tentative à backoff croissant sur les erreurs
/// transitoires uniquement, et un décodage JSON déporté hors du fil
/// principal avec `compute` pour la réponse de liste.
class UsersApi {
  UsersApi({http.Client? client}) : _client = client ?? http.Client();

  static const _host = 'dummyjson.com';
  static const _requestTimeout = Duration(seconds: 8);
  static const _selectFields = 'firstName,lastName,email,image,company';

  /// 1 essai initial + 3 nouvelles tentatives = 4 essais au total, espacés
  /// de 1 s / 2 s / 4 s — les trois délais donnés en exemple par le sujet.
  static const _maxAttempts = 4;

  final http.Client _client;

  void close() => _client.close();

  Future<UsersPage> fetchUsers({
    int limit = 20,
    int skip = 0,
    int? delayMs,
  }) {
    final uri = Uri.https(_host, '/users', {
      'limit': '$limit',
      'skip': '$skip',
      'select': _selectFields,
      if (delayMs != null) 'delay': '$delayMs',
    });
    return _requestUsersPage(uri);
  }

  Future<UsersPage> searchUsers(String query, {int limit = 10, int? delayMs}) {
    final uri = Uri.https(_host, '/users/search', {
      'q': query,
      'limit': '$limit',
      if (delayMs != null) 'delay': '$delayMs',
    });
    return _requestUsersPage(uri);
  }

  Future<Participant> fetchUserDetail(int id, {int? delayMs}) {
    final uri = Uri.https(_host, '/users/$id', {
      if (delayMs != null) 'delay': '$delayMs',
    });
    return _requestUserDetail(uri);
  }

  /// Point d'entrée imposé par le sujet pour démontrer, à la demande, la
  /// branche d'erreur du `FutureBuilder` et la nouvelle tentative à backoff
  /// croissant, sans dépendre d'une vraie coupure réseau.
  Future<UsersPage> triggerForcedServerError() async {
    final uri = Uri.https(_host, '/http/500');
    await _withRetry(() => _get(uri));
    // _get lève systématiquement une ServerException avant ce point : cette
    // ligne n'est accessible que si DummyJSON cesse un jour de renvoyer 500.
    throw const ServerException('Erreur serveur simulée.', 500);
  }

  /// Écriture (partie D). Volontairement hors du mécanisme de nouvelle
  /// tentative : voir README, "Partie D — écriture non idempotente".
  Future<Participant> addParticipant({
    required String firstName,
    required String lastName,
  }) async {
    final uri = Uri.https(_host, '/users/add');
    debugPrint('[UsersApi] ${_now()} POST $uri '
        '(écriture non idempotente — aucune nouvelle tentative automatique)');
    final response = await _execute(() => _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'firstName': firstName, 'lastName': lastName}),
        )
        .timeout(_requestTimeout));
    _checkStatus(response, uri);
    return _decodeParticipant(response);
  }

  // --- Requêtes de lecture, avec nouvelle tentative -------------------------

  Future<UsersPage> _requestUsersPage(Uri uri) async {
    final response = await _withRetry(() => _get(uri));
    try {
      // Décodage déporté hors du fil principal (partie C) : voir README
      // pour la justification du seuil de pertinence.
      return await compute(_decodeUsersPageInBackground, response.body);
    } catch (_) {
      throw const DecodingException(
        'La réponse du serveur est illisible, veuillez réessayer.',
      );
    }
  }

  Future<Participant> _requestUserDetail(Uri uri) async {
    final response = await _withRetry(() => _get(uri));
    return _decodeParticipant(response);
  }

  Participant _decodeParticipant(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Participant.fromJson(json);
    } on FormatException catch (e) {
      throw DecodingException(
        'La réponse du serveur est illisible : ${e.message}',
      );
    } on TypeError {
      throw const DecodingException(
        'La réponse du serveur est dans un format inattendu.',
      );
    }
  }

  // --- Couche transport : construction, envoi, vérification du code --------

  Future<http.Response> _get(Uri uri) async {
    debugPrint('[UsersApi] ${_now()} GET $uri');
    final response =
        await _execute(() => _client.get(uri).timeout(_requestTimeout));
    _checkStatus(response, uri);
    return response;
  }

  Future<http.Response> _execute(
    Future<http.Response> Function() call,
  ) async {
    try {
      return await call();
    } on TimeoutException {
      throw const RequestTimeoutException(
        'Délai dépassé, veuillez réessayer.',
      );
    } on http.ClientException catch (e) {
      throw NetworkException('Connexion impossible : ${e.message}');
    }
  }

  void _checkStatus(http.Response response, Uri uri) {
    final status = response.statusCode;
    if (status == 200 || status == 201) return;
    if (status == 404) {
      throw NotFoundException('Ressource introuvable ($uri).');
    }
    if (status >= 500) {
      throw ServerException(
        'Le service est momentanément indisponible, veuillez réessayer.',
        status,
      );
    }
    throw ServerException('La requête a échoué (code $status).', status);
  }

  // --- Nouvelle tentative à délai croissant, erreurs transitoires only -----

  Future<T> _withRetry<T>(Future<T> Function() action) async {
    var attempt = 1;
    while (true) {
      try {
        return await action();
      } on NotFoundException {
        rethrow; // jamais de nouvelle tentative sur un 404
      } on DecodingException {
        rethrow; // un corps illisible ne se corrigera pas en réessayant
      } on ServerException catch (e) {
        if (e.statusCode < 500 || attempt >= _maxAttempts) rethrow;
        await _backoff(attempt, e);
      } on NetworkException catch (e) {
        if (attempt >= _maxAttempts) rethrow;
        await _backoff(attempt, e);
      } on RequestTimeoutException catch (e) {
        if (attempt >= _maxAttempts) rethrow;
        await _backoff(attempt, e);
      }
      attempt++;
    }
  }

  Future<void> _backoff(int attempt, ApiException cause) async {
    final delay = Duration(seconds: 1 << (attempt - 1)); // 1s, 2s, 4s
    debugPrint('[UsersApi] ${_now()} tentative $attempt échouée '
        '(${cause.message}) — nouvelle tentative dans ${delay.inSeconds}s');
    await Future<void>.delayed(delay);
  }

  String _now() => DateTime.now().toIso8601String();
}

/// Fonction de niveau fichier : requis par `compute`, qui l'exécute dans un
/// isolate séparé et ne peut donc pas fermer sur l'état de [UsersApi].
UsersPage _decodeUsersPageInBackground(String body) {
  final decoded = jsonDecode(body) as Map<String, dynamic>;
  return UsersPage.fromJson(decoded);
}
