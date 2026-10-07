// Test d'un ChangeNotifier : `notifyListeners` est appelé quand l'état change
// réellement, et **pas** quand une règle métier refuse l'opération.
import 'package:event_planner_app/domain/failures.dart';
import 'package:event_planner_app/domain/models/registration.dart';
import 'package:event_planner_app/state/registration_cart_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late FakeRegistrationRepository repository;
  late RegistrationCartState cart;
  late int notifications;

  setUp(() {
    repository = FakeRegistrationRepository();
    cart = RegistrationCartState(repository: repository);
    notifications = 0;
    cart.addListener(() => notifications++);
  });

  tearDown(() => cart.dispose());

  CartOutcome addAda({int seats = 1, String email = 'ada@example.org'}) {
    return cart.add(
      event: buildEvent(capacity: 3, registered: 1),
      participantName: 'Ada',
      participantEmail: email,
      seats: seats,
    );
  }

  test('un ajout accepté notifie exactement une fois', () {
    expect(addAda(), CartOutcome.added);
    expect(notifications, 1);
    expect(cart.lines, hasLength(1));
  });

  test('un doublon est refusé et ne notifie pas', () {
    addAda();
    notifications = 0;

    // Même personne, même événement : la casse et les espaces ne trompent
    // pas la règle.
    expect(addAda(email: ' ADA@Example.org '), CartOutcome.rejectedDuplicate);
    expect(notifications, 0);
    expect(cart.lines, hasLength(1));
  });

  test('un dépassement de capacité est refusé et ne notifie pas', () {
    // 3 places, 1 prise : il en reste 2.
    expect(addAda(seats: 3), CartOutcome.rejectedNotEnoughSeats);
    expect(notifications, 0);
    expect(cart.isEmpty, isTrue);
  });

  test('la capacité compte aussi les places déjà au panier', () {
    expect(addAda(seats: 2), CartOutcome.added); // remplit l'événement
    notifications = 0;

    expect(addAda(email: 'bob@example.org'), CartOutcome.rejectedFull);
    expect(notifications, 0);
  });

  test('un événement complet à la source est refusé', () {
    final outcome = cart.add(
      event: buildEvent(capacity: 5, registered: 5),
      participantName: 'Ada',
      participantEmail: 'ada@example.org',
      seats: 1,
    );
    expect(outcome, CartOutcome.rejectedFull);
    expect(notifications, 0);
  });

  test('le retrait notifie ; retirer une ligne absente ne notifie pas', () {
    addAda();
    final line = cart.lines.single;
    notifications = 0;

    expect(cart.remove(line), CartOutcome.removed);
    expect(notifications, 1);

    expect(cart.remove(line), CartOutcome.rejectedNotFound);
    expect(notifications, 1);
  });

  test('un doublon avec une inscription déjà confirmée est refusé', () async {
    cart.bindUser('uid-1');
    repository.emitConfirmed(const [
      Registration(
        id: 'r1',
        userId: 'uid-1',
        eventId: '1',
        eventTitle: 'Conférence Flutter',
        participantName: 'Ada',
        participantEmail: 'ada@example.org',
        seats: 1,
      ),
    ]);
    await Future<void>.delayed(Duration.zero);
    notifications = 0;

    expect(addAda(), CartOutcome.rejectedDuplicate);
    expect(notifications, 0);
  });

  test(
    'confirmer enregistre le panier au nom de l\'utilisateur, puis le vide',
    () async {
      cart.bindUser('uid-1');
      addAda();

      final result = await cart.confirm();

      expect(result.isSuccess, isTrue);
      expect(cart.isEmpty, isTrue);
      expect(repository.saved.single.userId, 'uid-1');
    },
  );

  test('un refus du serveur à la confirmation conserve le panier', () async {
    cart.bindUser('uid-1');
    addAda();
    repository.failure = const PermissionFailure();

    final result = await cart.confirm();

    expect(result.isSuccess, isFalse);
    expect(result.error, isNotEmpty);
    expect(cart.lines, hasLength(1));
  });

  test('confirmer sans être connecté échoue proprement', () async {
    addAda();
    final result = await cart.confirm();
    expect(result.isSuccess, isFalse);
    expect(cart.lines, hasLength(1));
  });

  test('la déconnexion vide le panier', () {
    cart.bindUser('uid-1');
    addAda();
    cart.bindUser(null);
    expect(cart.isEmpty, isTrue);
  });
}
