import 'dart:convert';

import 'package:event_planner_app/domain/models/catalog_snapshot.dart';
import 'package:event_planner_app/domain/models/event.dart';
import 'package:event_planner_app/domain/models/registration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final event = Event(
    id: '42',
    title: 'Atelier « Dart » & tests',
    description: 'Une description\nsur deux lignes.',
    category: 'Atelier',
    start: DateTime(2026, 11, 2, 9, 30),
    end: DateTime(2026, 11, 2, 12),
    location: '12 rue de la Paix, Paris',
    capacity: 40,
    registered: 12,
    price: 12.5,
    imageUrl: 'https://example.org/a.webp',
    ownerId: 'uid-1',
  );

  test('Event : toJson puis fromJson reproduit l\'objet initial', () {
    // Passage par une vraie chaîne JSON, comme sur le disque.
    final decoded = jsonDecode(jsonEncode(event.toJson()));
    expect(Event.fromJson(decoded as Map<String, dynamic>), event);
  });

  test('Event : égalité de valeur et hashCode cohérents', () {
    final copy = event.copyWith();
    expect(copy, event);
    expect(copy.hashCode, event.hashCode);
    expect(event.copyWith(registered: 13), isNot(event));
  });

  test('Event : un événement sans propriétaire reste sans propriétaire', () {
    final publicEvent = Event.fromJson((event.toJson()..remove('ownerId')));
    expect(publicEvent.ownerId, isNull);
  });

  test('Event.fromJson refuse un JSON sans champ obligatoire', () {
    expect(
      () => Event.fromJson({'id': '1', 'title': 'Sans dates'}),
      throwsFormatException,
    );
  });

  test('Registration : aller-retour JSON', () {
    const registration = Registration(
      id: 'r1',
      userId: 'uid-1',
      eventId: '42',
      eventTitle: 'Atelier',
      participantName: 'Ada Lovelace',
      participantEmail: 'ada@example.org',
      seats: 2,
    );
    final decoded = jsonDecode(jsonEncode(registration.toJson()));
    expect(
      Registration.fromJson(decoded as Map<String, dynamic>),
      registration,
    );
  });

  test('CatalogSnapshot : aller-retour JSON (copie locale du catalogue)', () {
    final snapshot = CatalogSnapshot(
      events: [
        event,
        event.copyWith(id: '43'),
      ],
      total: 194,
      savedAt: DateTime(2026, 10, 7, 14, 30),
    );
    final decoded = jsonDecode(jsonEncode(snapshot.toJson()));
    final restored = CatalogSnapshot.fromJson(decoded as Map<String, dynamic>);
    expect(restored.events, snapshot.events);
    expect(restored.total, 194);
    expect(restored.savedAt, snapshot.savedAt);
  });
}
