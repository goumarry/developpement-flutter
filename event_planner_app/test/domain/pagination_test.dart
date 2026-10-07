import 'package:event_planner_app/domain/rules/pagination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pagination.itemsOnPage', () {
    test('page pleine', () {
      expect(Pagination.itemsOnPage(skip: 0, total: 194, limit: 20), 20);
    });

    test('dernière page partielle', () {
      expect(Pagination.itemsOnPage(skip: 180, total: 194, limit: 20), 14);
    });

    test('page hors bornes : rien à charger', () {
      expect(Pagination.itemsOnPage(skip: 194, total: 194, limit: 20), 0);
      expect(Pagination.itemsOnPage(skip: 500, total: 194, limit: 20), 0);
      expect(Pagination.itemsOnPage(skip: -20, total: 194, limit: 20), 0);
    });

    test('total à zéro', () {
      expect(Pagination.itemsOnPage(skip: 0, total: 0, limit: 20), 0);
    });
  });

  group('Pagination.pageCount', () {
    test('arrondit à la page supérieure', () {
      expect(Pagination.pageCount(total: 194, limit: 20), 10);
      expect(Pagination.pageCount(total: 200, limit: 20), 10);
      expect(Pagination.pageCount(total: 201, limit: 20), 11);
    });

    test('total à zéro : aucune page', () {
      expect(Pagination.pageCount(total: 0, limit: 20), 0);
    });
  });

  group('Pagination.hasMore', () {
    test('vrai tant que le total n\'est pas atteint', () {
      expect(Pagination.hasMore(loaded: 20, total: 194), isTrue);
    });

    test('faux quand tout est chargé, ou si le total a diminué', () {
      expect(Pagination.hasMore(loaded: 194, total: 194), isFalse);
      expect(Pagination.hasMore(loaded: 200, total: 194), isFalse);
      expect(Pagination.hasMore(loaded: 0, total: 0), isFalse);
    });
  });
}
