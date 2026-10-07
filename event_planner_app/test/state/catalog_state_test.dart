import 'package:event_planner_app/domain/failures.dart';
import 'package:event_planner_app/domain/models/app_preferences.dart';
import 'package:event_planner_app/domain/models/catalog_snapshot.dart';
import 'package:event_planner_app/domain/rules/pagination.dart';
import 'package:event_planner_app/state/catalog_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late FakeEventRepository repository;
  late FakeCatalogCache cache;
  late CatalogState catalog;

  setUp(() {
    repository = FakeEventRepository(
      events: [
        for (var i = 1; i <= 45; i++)
          buildEvent(id: '$i', title: 'Événement $i'),
      ],
    );
    cache = FakeCatalogCache();
    catalog = CatalogState(repository: repository, cache: cache);
  });

  tearDown(() => catalog.dispose());

  test('pagine jusqu\'au total puis s\'arrête de charger', () async {
    await catalog.loadFirstPage();
    expect(catalog.events, hasLength(Pagination.pageSize));
    expect(catalog.total, 45);
    expect(catalog.hasMore, isTrue);

    await catalog.loadMore();
    expect(catalog.events, hasLength(40));
    expect(catalog.nextPageSize, 5, reason: 'dernière page partielle');

    await catalog.loadMore();
    expect(catalog.events, hasLength(45));
    expect(catalog.hasMore, isFalse);

    final callsBefore = repository.calls.length;
    await catalog.loadMore();
    expect(
      repository.calls,
      hasLength(callsBefore),
      reason: 'aucun appel inutile',
    );
    expect(repository.calls.map((call) => call.skip), [0, 20, 40]);
  });

  test('recherche sans résultat : état « vide », pas « erreur »', () async {
    await catalog.loadFirstPage(query: 'introuvable');
    expect(catalog.status, CatalogStatus.empty);
    expect(catalog.errorMessage, isNull);
  });

  test('échec sans copie locale : état « erreur » avec message', () async {
    repository.failure = const ServerFailure(500);
    await catalog.loadFirstPage();
    expect(catalog.status, CatalogStatus.error);
    expect(catalog.errorMessage, isNotEmpty);
    expect(catalog.isStale, isFalse);
  });

  test('mode dégradé : l\'échec réseau retombe sur la copie locale', () async {
    final savedAt = DateTime(2026, 10, 7, 14, 30);
    cache.snapshot = CatalogSnapshot(
      events: [buildEvent(id: '7', title: 'En cache')],
      total: 1,
      savedAt: savedAt,
    );
    repository.failure = const NetworkFailure();

    await catalog.loadFirstPage();

    expect(catalog.status, CatalogStatus.loaded);
    expect(catalog.events.single.title, 'En cache');
    expect(catalog.isStale, isTrue);
    expect(catalog.staleSince, savedAt);
    expect(catalog.hasMore, isFalse, reason: 'on ne pagine pas une copie');
  });

  test(
    'un chargement réussi met à jour la copie et sort du mode dégradé',
    () async {
      cache.snapshot = CatalogSnapshot(
        events: [buildEvent()],
        total: 1,
        savedAt: DateTime(2026),
      );
      repository.failure = const NetworkFailure();
      await catalog.loadFirstPage();
      expect(catalog.isStale, isTrue);

      repository.failure = null;
      await catalog.refresh();

      expect(catalog.isStale, isFalse);
      expect(cache.snapshot!.events, hasLength(Pagination.pageSize));
      expect(cache.writes, 1);
    },
  );

  test(
    'l\'échec d\'une page suivante conserve les pages déjà chargées',
    () async {
      await catalog.loadFirstPage();
      repository.failure = const TimeoutFailure();

      await catalog.loadMore();

      expect(catalog.status, CatalogStatus.loaded);
      expect(catalog.events, hasLength(Pagination.pageSize));
      expect(catalog.loadMoreError, isNotEmpty);
      expect(catalog.isLoadingMore, isFalse);
    },
  );

  test('le tri s\'applique aux événements chargés', () async {
    repository.events = [
      buildEvent(id: '1', title: 'Zumba', capacity: 10, registered: 9),
      buildEvent(id: '2', title: 'atelier', capacity: 10, registered: 1),
    ];
    await catalog.loadFirstPage();

    catalog.setSort(EventSort.title);
    expect(catalog.events.map((e) => e.title), ['atelier', 'Zumba']);

    catalog.setSort(EventSort.remainingSeats);
    expect(catalog.events.first.title, 'atelier');
  });
}
