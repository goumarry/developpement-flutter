import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:event_planner_nav/data/sample_events.dart';
import 'package:event_planner_nav/models/formule.dart';
import 'package:event_planner_nav/routes/app_routes.dart';
import 'package:event_planner_nav/routes/route_generator.dart';
import 'package:event_planner_nav/screens/event_detail_screen.dart';
import 'package:event_planner_nav/screens/not_found_screen.dart';
import 'package:event_planner_nav/utils/date_label.dart';

/// Ces tests ne portent pas sur le rendu visuel (les [Image.network] échouent
/// dans l'environnement de test, c'est normal et documenté par Flutter). Ils
/// vérifient :
/// - que le jeu de données du TP 2 est intact (cas limites de mise en page) ;
/// - que chaque événement porte un `id` unique (nouveauté du TP 3) ;
/// - que le générateur de routes traite bien les cas nominaux et les trois
///   cas d'erreur d'argument de la route de détail.
void main() {
  group('Jeu de données (repris du TP 2)', () {
    test('contient au moins huit événements', () {
      expect(sampleEvents.length, greaterThanOrEqualTo(8));
    });

    test('chaque événement a un id unique et non vide', () {
      final ids = sampleEvents.map((e) => e.id).toList();
      expect(ids.every((id) => id.isNotEmpty), isTrue);
      expect(ids.toSet().length, ids.length);
    });

    test('contient un titre de plus de 70 caractères', () {
      expect(sampleEvents.any((e) => e.title.length > 70), isTrue);
    });

    test('contient un événement complet (isSoldOut)', () {
      expect(sampleEvents.any((e) => e.isSoldOut), isTrue);
    });

    test('contient un événement en liste d\'attente (registered > capacity)', () {
      expect(sampleEvents.any((e) => e.registered > e.capacity), isTrue);
    });

    test('dateLabel formate correctement une date connue', () {
      expect(dateLabel(DateTime(2026, 6, 12, 18, 30)), 'ven. 12 juin, 18h30');
    });
  });

  group('findEventById', () {
    test('résout un identifiant existant', () {
      expect(findEventById('evt-001'), isNotNull);
    });

    test('renvoie null pour un identifiant inconnu', () {
      expect(findEventById('evt-999'), isNull);
    });
  });

  group('RouteGenerator.parcoursRoute — route de détail', () {
    Route<dynamic>? route(Object? arguments) => RouteGenerator.parcoursRoute(
          RouteSettings(name: AppRoutes.eventDetail, arguments: arguments),
        );

    test('cas nominal : id valide -> EventDetailScreen', () {
      final r = route('evt-002') as MaterialPageRoute;
      expect(r.builder(_FakeContext()), isA<EventDetailScreen>());
    });

    test('argument absent -> écran d\'erreur', () {
      final r = route(null) as MaterialPageRoute;
      expect(r.builder(_FakeContext()), isA<NotFoundScreen>());
    });

    test('argument de type inattendu -> écran d\'erreur', () {
      final r = route(42) as MaterialPageRoute;
      expect(r.builder(_FakeContext()), isA<NotFoundScreen>());
    });

    test('id inexistant -> écran d\'erreur', () {
      final r = route('evt-999') as MaterialPageRoute;
      expect(r.builder(_FakeContext()), isA<NotFoundScreen>());
    });
  });

  group('RouteGenerator — confirmation', () {
    test('arguments ConfirmationArgs -> ConfirmationScreen', () {
      final args = ConfirmationArgs(
        event: sampleEvents.first,
        formule: const Formule(
          id: 'x',
          label: 'X',
          priceEur: 10,
          description: 'test',
        ),
      );
      final r = RouteGenerator.parcoursRoute(
        RouteSettings(name: AppRoutes.confirmation, arguments: args),
      );
      expect(r, isA<PageRoute>());
    });

    test('mauvais type d\'arguments -> route d\'erreur (MaterialPageRoute)', () {
      final r = RouteGenerator.parcoursRoute(
        const RouteSettings(name: AppRoutes.confirmation, arguments: 'nope'),
      ) as MaterialPageRoute;
      expect(r.builder(_FakeContext()), isA<NotFoundScreen>());
    });
  });

  test('route inconnue -> NotFoundScreen', () {
    final r = RouteGenerator.unknownRoute(
      const RouteSettings(name: '/route-qui-nexiste-pas'),
    ) as MaterialPageRoute;
    expect(r.builder(_FakeContext()), isA<NotFoundScreen>());
  });
}

/// Contexte factice : les `builder` testés ici ne consultent pas le contexte.
class _FakeContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
