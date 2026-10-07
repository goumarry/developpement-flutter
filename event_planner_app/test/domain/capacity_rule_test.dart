// Tests unitaires de logique métier pure : aucun import Flutter dans le
// fichier testé (`package:test` suffirait ; `flutter_test` n'est utilisé que
// comme lanceur).
import 'package:event_planner_app/domain/rules/capacity_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CapacityRule.check', () {
    test('accepte une demande qui tient dans la capacité', () {
      expect(
        CapacityRule.check(capacity: 10, taken: 3, requestedSeats: 2),
        CapacityDecision.accepted,
      );
    });

    test('refuse quand la capacité est atteinte (égalité stricte)', () {
      expect(
        CapacityRule.check(capacity: 10, taken: 10, requestedSeats: 1),
        CapacityDecision.rejectedFull,
      );
    });

    test('refuse au-delà de la limite, même d\'une seule place', () {
      expect(
        CapacityRule.check(capacity: 10, taken: 9, requestedSeats: 2),
        CapacityDecision.rejectedNotEnoughSeats,
      );
    });

    test('accepte la demande qui remplit exactement l\'événement', () {
      expect(
        CapacityRule.check(capacity: 10, taken: 8, requestedSeats: 2),
        CapacityDecision.accepted,
      );
    });

    test('refuse une source incohérente où les inscrits dépassent', () {
      expect(
        CapacityRule.check(capacity: 5, taken: 7, requestedSeats: 1),
        CapacityDecision.rejectedFull,
      );
    });

    test('refuse un nombre de places nul ou négatif', () {
      for (final seats in [0, -1]) {
        expect(
          CapacityRule.check(capacity: 10, taken: 0, requestedSeats: seats),
          CapacityDecision.rejectedInvalidSeats,
        );
      }
    });

    test('une capacité nulle est toujours complète', () {
      expect(
        CapacityRule.check(capacity: 0, taken: 0, requestedSeats: 1),
        CapacityDecision.rejectedFull,
      );
    });
  });

  group('CapacityRule.remaining', () {
    test('donne la différence, jamais négative', () {
      expect(CapacityRule.remaining(capacity: 10, taken: 4), 6);
      expect(CapacityRule.remaining(capacity: 10, taken: 10), 0);
      expect(CapacityRule.remaining(capacity: 10, taken: 12), 0);
    });
  });
}
