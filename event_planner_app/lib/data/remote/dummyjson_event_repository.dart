import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/failures.dart';
import '../../domain/models/event.dart';
import '../../domain/models/event_page.dart';
import '../../domain/models/network_demo_mode.dart';
import '../../domain/repositories/event_repository.dart';

/// Catalogue d'événements adossé à https://dummyjson.com.
///
/// DummyJSON n'expose pas de ressource « événement » : la ressource
/// `products` est **réinterprétée** (voir [eventFromProduct]). Seul fichier de
/// l'application qui connaît la forme du JSON distant.
///
/// Toutes les erreurs sortent sous forme d'`AppFailure` : ni
/// `http.ClientException`, ni `TimeoutException`, ni `FormatException` ne
/// franchissent cette classe.
class DummyJsonEventRepository implements EventRepository {
  DummyJsonEventRepository({
    required this._client,
    this.requestTimeout = const Duration(seconds: 8),
    this.maxAttempts = 2,
    this.retryDelay = const Duration(seconds: 1),
    NetworkDemoMode Function()? demoMode,
  }) : _demoMode = demoMode ?? _alwaysNormal;

  static NetworkDemoMode _alwaysNormal() => NetworkDemoMode.normal;

  static const String _host = 'dummyjson.com';

  /// Seuls les champs utiles sont demandés : réponse plus légère.
  static const String _select =
      'id,title,description,category,price,stock,minimumOrderQuantity,thumbnail';

  final http.Client _client;

  /// Délai maximal d'une requête ; injectable pour tester le dépassement.
  final Duration requestTimeout;

  /// Nombre total d'essais pour une erreur **transitoire** (réseau, délai,
  /// 5xx). Un 404 ou un JSON illisible ne sont jamais rejoués.
  final int maxAttempts;
  final Duration retryDelay;

  /// Lu **à chaque requête** : le mode de démonstration choisi dans les
  /// réglages s'applique immédiatement, sans recréer le dépôt.
  final NetworkDemoMode Function() _demoMode;

  @override
  Future<EventPage> fetchEvents({
    required int limit,
    required int skip,
    String? query,
  }) async {
    final search = query?.trim() ?? '';
    final uri = Uri.https(
      _host,
      search.isEmpty ? '/products' : '/products/search',
      {
        if (search.isNotEmpty) 'q': search,
        'limit': '$limit',
        'skip': '$skip',
        'select': _select,
      },
    );
    final json = await _getJson(uri);
    final products = json['products'];
    final total = json['total'];
    if (products is! List || total is! int) throw const DecodingFailure();
    try {
      return EventPage(
        events: [
          for (final product in products)
            eventFromProduct((product as Map).cast<String, dynamic>()),
        ],
        total: total,
        skip: skip,
        limit: limit,
      );
    } on FormatException {
      throw const DecodingFailure();
    } on TypeError {
      throw const DecodingFailure();
    }
  }

  @override
  Future<Event> fetchEventById(String id) async {
    final uri = Uri.https(_host, '/products/$id', {'select': _select});
    final json = await _getJson(uri);
    try {
      return eventFromProduct(json);
    } on FormatException {
      throw const DecodingFailure();
    }
  }

  /// Réinterprétation d'un produit DummyJSON en événement :
  /// * `stock` -> places restantes ;
  /// * `minimumOrderQuantity` -> places déjà prises ;
  /// * capacité = somme des deux (un produit en rupture devient un événement
  ///   complet) ;
  /// * `price` -> tarif, `thumbnail` -> visuel ;
  /// * la date n'existe pas côté API : elle est **dérivée de l'identifiant**
  ///   (un créneau tous les deux jours à partir d'une date fixe), donc stable
  ///   d'un appel à l'autre.
  static Event eventFromProduct(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id is! int || title is! String) {
      throw const FormatException('Produit sans identifiant ou sans titre');
    }
    final stock = json['stock'];
    final taken = json['minimumOrderQuantity'];
    final remaining = stock is int && stock > 0 ? stock : 0;
    final registered = taken is int && taken > 0 ? taken : 0;
    final price = json['price'];
    final category = json['category'];
    final start = _firstSlot.add(
      Duration(days: (id - 1) * 2, hours: (id % 4) * 3),
    );
    return Event(
      id: '$id',
      title: title,
      description: json['description'] is String
          ? json['description'] as String
          : '',
      category: category is String ? _categoryLabel(category) : 'Divers',
      start: start,
      end: start.add(const Duration(hours: 2)),
      capacity: remaining + registered,
      registered: registered,
      price: price is num ? price.toDouble() : 0,
      imageUrl: json['thumbnail'] is String ? json['thumbnail'] as String : '',
    );
  }

  static final DateTime _firstSlot = DateTime(2026, 11, 2, 9);

  /// `home-decoration` -> `Home decoration`.
  static String _categoryLabel(String slug) {
    final words = slug.replaceAll('-', ' ').trim();
    if (words.isEmpty) return 'Divers';
    return words[0].toUpperCase() + words.substring(1);
  }

  // --- Transport -----------------------------------------------------------

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    var attempt = 1;
    while (true) {
      try {
        return await _getJsonOnce(uri);
      } on AppFailure catch (failure) {
        if (!_isTransient(failure) || attempt >= maxAttempts) rethrow;
        attempt++;
        await Future<void>.delayed(retryDelay);
      }
    }
  }

  bool _isTransient(AppFailure failure) =>
      failure is NetworkFailure ||
      failure is TimeoutFailure ||
      (failure is ServerFailure && failure.statusCode >= 500);

  Future<Map<String, dynamic>> _getJsonOnce(Uri uri) async {
    final target = switch (_demoMode()) {
      NetworkDemoMode.normal => uri,
      NetworkDemoMode.slow => uri.replace(
        queryParameters: {...uri.queryParameters, 'delay': '3000'},
      ),
      NetworkDemoMode.serverError => Uri.https(_host, '/http/500'),
    };
    final http.Response response;
    try {
      response = await _client.get(target).timeout(requestTimeout);
    } on TimeoutException {
      throw const TimeoutFailure();
    } on http.ClientException {
      throw const NetworkFailure();
    } on Exception {
      // Erreur de transport non enveloppée par `http` (poignée de main TLS…).
      throw const NetworkFailure();
    }

    final status = response.statusCode;
    if (status == 404) throw const NotFoundFailure();
    if (status != 200) throw ServerFailure(status);

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const DecodingFailure();
      return decoded;
    } on FormatException {
      throw const DecodingFailure();
    }
  }
}
