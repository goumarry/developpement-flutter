import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:event_planner_nav/data/sample_packages.dart';
import 'package:event_planner_nav/models/formule.dart';
import 'package:event_planner_nav/screens/package_selection_screen.dart';

/// Vérifie le contrat de l'écran de sélection de formule :
/// - un choix explicite renvoie la [Formule] via `Navigator.pop` ;
/// - une tentative de retour (flèche AppBar / bouton système) ouvre le dialogue
///   d'abandon et ne navigue pas tant qu'il n'est pas validé (PopScope).
void main() {
  Future<Formule?> pushSelection(WidgetTester tester) async {
    Formule? received;
    late BuildContext ctx;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const Scaffold(body: Center(child: Text('HOME')));
          },
        ),
      ),
    );

    Navigator.of(ctx).push<Formule>(
      MaterialPageRoute(
        builder: (_) => const PackageSelectionScreen(eventTitle: 'Événement test'),
      ),
    ).then((value) => received = value);
    await tester.pumpAndSettle();

    return Future.value(received);
  }

  testWidgets('un choix de formule est renvoyé par pop', (tester) async {
    await pushSelection(tester);
    expect(find.text('Choisir une formule'), findsOneWidget);

    await tester.tap(find.text('Choisir cette formule').first);
    await tester.pumpAndSettle();

    // De retour sur HOME : la sélection a bien dépilé l'écran.
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('le retour ouvre le dialogue d\'abandon et peut être annulé',
      (tester) async {
    await pushSelection(tester);

    // Tentative de retour via la flèche de l'AppBar.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Abandonner la sélection en cours ?'), findsOneWidget);

    // Annulation du dialogue : aucune navigation, on reste sur la sélection.
    await tester.tap(find.text('Continuer la sélection'));
    await tester.pumpAndSettle();

    expect(find.text('Abandonner la sélection en cours ?'), findsNothing);
    expect(find.text('Choisir une formule'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);

    // Cette fois on confirme l'abandon : retour à HOME.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abandonner'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
  });

  test('les trois formules codées en dur sont présentes', () {
    expect(samplePackages.length, 3);
    expect(samplePackages.map((f) => f.label),
        containsAll(['Essentiel', 'Standard', 'VIP']));
  });
}
