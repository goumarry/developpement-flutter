import 'package:flutter_test/flutter_test.dart';

import 'package:event_planner_ui/data/sample_events.dart';
import 'package:event_planner_ui/utils/date_label.dart';

/// Ces tests ne portent volontairement pas sur le rendu visuel (les
/// [Image.network] échouent dans l'environnement de test, ce qui est normal
/// et documenté par Flutter). Ils vérifient à la place que le jeu de données
/// contient bien les cas limites exigés par l'énoncé — le "protocole de
/// test de la mise en page" — pour que quiconque modifie sample_events.dart
/// soit averti s'il supprime un cas limite par erreur.
void main() {
  test('contient au moins huit événements', () {
    expect(sampleEvents.length, greaterThanOrEqualTo(8));
  });

  test('contient un titre de plus de 70 caractères', () {
    expect(sampleEvents.any((e) => e.title.length > 70), isTrue);
  });

  test('contient un événement complet (isSoldOut)', () {
    expect(sampleEvents.any((e) => e.isSoldOut), isTrue);
  });

  test('contient un événement en ligne sans localisation utile', () {
    expect(
      sampleEvents.any((e) => e.isOnline && e.city.isEmpty && e.venue.isEmpty),
      isTrue,
    );
  });

  test('contient un événement en liste d\'attente (registered > capacity)', () {
    expect(sampleEvents.any((e) => e.registered > e.capacity), isTrue);
  });

  test('contient un nom de lieu long', () {
    expect(sampleEvents.any((e) => e.venue.length > 40), isTrue);
  });

  test('dateLabel formate correctement une date connue', () {
    // Vendredi 12 juin 2026, 18h30.
    expect(dateLabel(DateTime(2026, 6, 12, 18, 30)), 'ven. 12 juin, 18h30');
  });

  test('dateLabel pad les minutes à un chiffre', () {
    expect(dateLabel(DateTime(2026, 6, 12, 9, 5)), 'ven. 12 juin, 09h05');
  });
}
