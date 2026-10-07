// Comportement en cas d'échec réseau, avec un double du client HTTP
// (`MockClient`, fourni par le paquet `http` lui-même) : aucun appel réel.
import 'dart:convert';

import 'package:event_planner_app/data/remote/dummyjson_event_repository.dart';
import 'package:event_planner_app/domain/failures.dart';
import 'package:event_planner_app/domain/models/network_demo_mode.dart';
import 'package:event_planner_app/state/catalog_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fakes.dart';

DummyJsonEventRepository repositoryOver(
  MockClient client, {
  NetworkDemoMode Function()? demoMode,
}) {
  return DummyJsonEventRepository(
    client: client,
    requestTimeout: const Duration(milliseconds: 50),
    retryDelay: Duration.zero, // pas d'attente réelle entre deux essais
    demoMode: demoMode,
  );
}

Future<void> expectFailure<T extends AppFailure>(
  DummyJsonEventRepository repository,
) {
  return expectLater(
    repository.fetchEvents(limit: 20, skip: 0),
    throwsA(isA<T>()),
  );
}

void main() {
  group('DummyJsonEventRepository — échecs', () {
    test('HTTP 500 -> ServerFailure, après une nouvelle tentative', () async {
      var calls = 0;
      final repository = repositoryOver(
        MockClient((request) async {
          calls++;
          return http.Response('Internal Server Error', 500);
        }),
      );

      await expectLater(
        repository.fetchEvents(limit: 20, skip: 0),
        throwsA(
          isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 500),
        ),
      );
      expect(calls, 2, reason: 'erreur transitoire : rejouée une fois');
    });

    test('panne de connexion -> NetworkFailure', () async {
      final repository = repositoryOver(
        MockClient(
          (_) async => throw http.ClientException('Connexion refusée'),
        ),
      );
      await expectFailure<NetworkFailure>(repository);
    });

    test('réponse trop lente -> TimeoutFailure', () async {
      final repository = repositoryOver(
        MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return http.Response('{}', 200);
        }),
      );
      await expectFailure<TimeoutFailure>(repository);
    });

    test('JSON illisible -> DecodingFailure, jamais rejoué', () async {
      var calls = 0;
      final repository = repositoryOver(
        MockClient((_) async {
          calls++;
          return http.Response('<html>pas du JSON</html>', 200);
        }),
      );
      await expectFailure<DecodingFailure>(repository);
      expect(calls, 1);
    });

    test('JSON valide mais de forme inattendue -> DecodingFailure', () async {
      final repository = repositoryOver(
        MockClient((_) async => http.Response('{"products": "oups"}', 200)),
      );
      await expectFailure<DecodingFailure>(repository);
    });

    test('HTTP 404 -> NotFoundFailure, jamais rejoué', () async {
      var calls = 0;
      final repository = repositoryOver(
        MockClient((_) async {
          calls++;
          return http.Response('{"message": "not found"}', 404);
        }),
      );
      await expectLater(
        repository.fetchEventById('9999'),
        throwsA(isA<NotFoundFailure>()),
      );
      expect(calls, 1);
    });
  });

  group('Couche appelante (CatalogState) sur un client en échec', () {
    test(
      'produit l\'état d\'erreur, pas une exception non rattrapée',
      () async {
        final catalog = CatalogState(
          repository: repositoryOver(
            MockClient((_) async => http.Response('', 500)),
          ),
          cache: FakeCatalogCache(),
        );
        addTearDown(catalog.dispose);

        await catalog.loadFirstPage(); // ne doit pas lever

        expect(catalog.status, CatalogStatus.error);
        expect(catalog.errorMessage, contains('500'));
      },
    );
  });

  group('DummyJsonEventRepository — succès et requêtes émises', () {
    final body = jsonEncode({
      'products': [
        {
          'id': 117,
          'title': 'Complet',
          'category': 'home-decoration',
          'price': 12.5,
          'stock': 0,
          'minimumOrderQuantity': 8,
          'thumbnail': 'https://example.org/t.webp',
        },
      ],
      'total': 194,
      'skip': 20,
      'limit': 20,
    });

    test('limit, skip et recherche sont transmis ; le total est lu', () async {
      late Uri requested;
      final repository = repositoryOver(
        MockClient((request) async {
          requested = request.url;
          return http.Response(body, 200);
        }),
      );

      final page = await repository.fetchEvents(
        limit: 20,
        skip: 20,
        query: 'phone',
      );

      expect(requested.path, '/products/search');
      expect(requested.queryParameters['q'], 'phone');
      expect(requested.queryParameters['limit'], '20');
      expect(requested.queryParameters['skip'], '20');
      expect(page.total, 194);
    });

    test('un produit en rupture devient un événement complet', () async {
      final repository = repositoryOver(
        MockClient((_) async => http.Response(body, 200)),
      );

      final event = (await repository.fetchEvents(
        limit: 20,
        skip: 0,
      )).events.single;

      expect(event.id, '117');
      expect(event.category, 'Home decoration');
      expect(event.capacity, 8);
      expect(event.registered, 8);
      expect(event.isFull, isTrue);
    });

    test('mode démo « Erreur 500 » : l\'appel vise /http/500', () async {
      late Uri requested;
      final repository = repositoryOver(
        MockClient((request) async {
          requested = request.url;
          return http.Response('', 500);
        }),
        demoMode: () => NetworkDemoMode.serverError,
      );

      await expectFailure<ServerFailure>(repository);
      expect(requested.path, '/http/500');
    });

    test('mode démo « Latence » : ajoute ?delay= à l\'appel', () async {
      late Uri requested;
      final repository = repositoryOver(
        MockClient((request) async {
          requested = request.url;
          return http.Response(body, 200);
        }),
        demoMode: () => NetworkDemoMode.slow,
      );

      await repository.fetchEvents(limit: 20, skip: 0);
      expect(requested.queryParameters['delay'], '3000');
    });
  });
}
