import 'package:event_planner_app/presentation/widgets/registration_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  late List<RegistrationRequest> submitted;

  setUp(() => submitted = []);

  Future<void> pumpForm(WidgetTester tester, {int remainingSeats = 2}) {
    return tester.pumpWidget(
      testApp(
        SingleChildScrollView(
          child: RegistrationForm(
            remainingSeats: remainingSeats,
            onSubmit: submitted.add,
          ),
        ),
      ),
    );
  }

  Future<void> fill(
    WidgetTester tester, {
    String name = 'Ada Lovelace',
    String email = 'ada@example.org',
    String? confirmation,
    String seats = '1',
  }) async {
    Future<void> enter(String label, String text) =>
        tester.enterText(find.widgetWithText(TextFormField, label), text);
    await enter('Nom du participant', name);
    await enter('Courriel', email);
    await enter('Confirmation du courriel', confirmation ?? email);
    await enter('Nombre de places', seats);
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.text('Ajouter à mes inscriptions');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  testWidgets('formulaire vide : soumission refusée, erreurs affichées', (
    tester,
  ) async {
    await pumpForm(tester);
    await submit(tester);

    expect(submitted, isEmpty);
    expect(find.text('Ce champ est obligatoire.'), findsNWidgets(2));
    expect(find.text('Confirmez votre adresse courriel.'), findsOneWidget);
  });

  testWidgets('validation croisée : confirmation de courriel différente', (
    tester,
  ) async {
    await pumpForm(tester);
    await fill(tester, confirmation: 'autre@example.org');
    await submit(tester);

    expect(submitted, isEmpty);
    expect(find.textContaining('ne correspondent pas'), findsOneWidget);
  });

  testWidgets('validation croisée : plus de places que de places restantes', (
    tester,
  ) async {
    await pumpForm(tester, remainingSeats: 2);
    await fill(tester, seats: '3');
    await submit(tester);

    expect(submitted, isEmpty);
    expect(find.textContaining('Il ne reste que 2'), findsOneWidget);
  });

  testWidgets('saisie valide : soumission avec les valeurs nettoyées', (
    tester,
  ) async {
    await pumpForm(tester);
    await fill(tester, name: '  Ada Lovelace ', seats: '2');
    await submit(tester);

    expect(submitted, hasLength(1));
    expect(submitted.single.name, 'Ada Lovelace');
    expect(submitted.single.email, 'ada@example.org');
    expect(submitted.single.seats, 2);
  });
}
