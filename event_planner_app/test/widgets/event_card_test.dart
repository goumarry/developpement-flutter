import 'package:event_planner_app/presentation/widgets/capacity_gauge.dart';
import 'package:event_planner_app/presentation/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import 'harness.dart';

void main() {
  testWidgets('capacité atteinte : la jauge affiche « Complet »',
      (tester) async {
    await tester.pumpWidget(
      testApp(EventCard(event: buildEvent(capacity: 40, registered: 40))),
    );

    expect(find.text('Complet'), findsOneWidget);
    expect(find.textContaining('/ 40 places'), findsNothing);
    // Équivalent textuel pour un lecteur d'écran.
    expect(
      tester.getSemantics(find.byType(CapacityGauge)).value,
      contains('Complet'),
    );
  });

  testWidgets('places disponibles : la jauge affiche le décompte',
      (tester) async {
    await tester.pumpWidget(
      testApp(EventCard(event: buildEvent(capacity: 40, registered: 12))),
    );

    expect(find.text('12 / 40 places'), findsOneWidget);
    expect(find.text('Complet'), findsNothing);
  });

  testWidgets('aucun débordement : écran étroit, titre long, grande police',
      (tester) async {
    tester.view.physicalSize = const Size(280, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: testApp(
          ListView(
            children: [
              EventCard(
                event: buildEvent(
                  title: 'Un titre d\'événement démesurément long pour '
                      'vérifier que la carte ne déborde jamais',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('la carte est activable et transmet le toucher', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      testApp(EventCard(event: buildEvent(), onTap: () => taps++)),
    );

    await tester.tap(find.byType(EventCard));
    expect(taps, 1);
  });
}
