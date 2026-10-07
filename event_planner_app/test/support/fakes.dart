import 'dart:async';

import 'package:event_planner_app/domain/failures.dart';
import 'package:event_planner_app/domain/models/app_preferences.dart';
import 'package:event_planner_app/domain/models/catalog_snapshot.dart';
import 'package:event_planner_app/domain/models/event.dart';
import 'package:event_planner_app/domain/models/event_page.dart';
import 'package:event_planner_app/domain/models/registration.dart';
import 'package:event_planner_app/domain/models/user_profile.dart';
import 'package:event_planner_app/domain/models/write_status.dart';
import 'package:event_planner_app/domain/repositories/auth_repository.dart';
import 'package:event_planner_app/domain/repositories/catalog_cache.dart';
import 'package:event_planner_app/domain/repositories/event_repository.dart';
import 'package:event_planner_app/domain/repositories/organizer_event_repository.dart';
import 'package:event_planner_app/domain/repositories/preferences_repository.dart';
import 'package:event_planner_app/domain/repositories/registration_repository.dart';

/// Doubles de test écrits à la main : ils implémentent les interfaces du
/// domaine, sans réseau, sans disque et sans Firebase.

/// Événement de test ; seuls les champs utiles au cas sont à préciser.
Event buildEvent({
  String id = '1',
  String title = 'Conférence Flutter',
  int capacity = 10,
  int registered = 0,
  double price = 0,
  String? ownerId,
  DateTime? start,
}) {
  final begin = start ?? DateTime(2026, 11, 2, 9);
  return Event(
    id: id,
    title: title,
    category: 'Conférence',
    start: begin,
    end: begin.add(const Duration(hours: 2)),
    capacity: capacity,
    registered: registered,
    price: price,
    ownerId: ownerId,
  );
}

/// Catalogue en mémoire, paginé comme le vrai. [failure] non nul : tout appel
/// échoue avec cette erreur.
class FakeEventRepository implements EventRepository {
  FakeEventRepository({List<Event>? events}) : events = events ?? [];

  List<Event> events;
  AppFailure? failure;
  final List<({int limit, int skip, String? query})> calls = [];

  @override
  Future<EventPage> fetchEvents({
    required int limit,
    required int skip,
    String? query,
  }) async {
    calls.add((limit: limit, skip: skip, query: query));
    final error = failure;
    if (error != null) throw error;
    final matches = query == null
        ? events
        : events
            .where((e) => e.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
    return EventPage(
      events: matches.skip(skip).take(limit).toList(),
      total: matches.length,
      skip: skip,
      limit: limit,
    );
  }

  @override
  Future<Event> fetchEventById(String id) async {
    final error = failure;
    if (error != null) throw error;
    return events.firstWhere(
      (event) => event.id == id,
      orElse: () => throw const NotFoundFailure(),
    );
  }
}

class FakeCatalogCache implements CatalogCache {
  CatalogSnapshot? snapshot;
  int writes = 0;

  @override
  Future<CatalogSnapshot?> read() async => snapshot;

  @override
  Future<void> write(CatalogSnapshot snapshot) async {
    writes++;
    this.snapshot = snapshot;
  }
}

class FakeRegistrationRepository implements RegistrationRepository {
  final _controller = StreamController<List<Registration>>.broadcast();
  final List<Registration> saved = [];
  AppFailure? failure;

  /// Simule l'arrivée des inscriptions confirmées depuis le serveur.
  void emitConfirmed(List<Registration> registrations) =>
      _controller.add(registrations);

  @override
  Stream<List<Registration>> watchConfirmed(String userId) =>
      _controller.stream;

  @override
  Future<WriteStatus> confirmAll(List<Registration> registrations) async {
    final error = failure;
    if (error != null) throw error;
    saved.addAll(registrations);
    return WriteStatus.confirmed;
  }

  @override
  Future<WriteStatus> cancel(String registrationId) async =>
      WriteStatus.confirmed;
}

class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<UserProfile?>.broadcast();

  /// Simule un changement de session venu du SDK.
  void emit(UserProfile? user) => _controller.add(user);

  @override
  Stream<UserProfile?> authStateChanges() => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    emit(UserProfile(uid: 'uid-$email', email: email));
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) =>
      signIn(email: email, password: password);

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async => emit(null);
}

class FakeOrganizerEventRepository implements OrganizerEventRepository {
  final _controller = StreamController<List<Event>>.broadcast();

  @override
  Stream<List<Event>> watchOwnEvents(String ownerId) => _controller.stream;

  @override
  Future<WriteStatus> create(Event event) async => WriteStatus.confirmed;

  @override
  Future<WriteStatus> update(Event event) async => WriteStatus.confirmed;

  @override
  Future<WriteStatus> delete(String eventId) async => WriteStatus.confirmed;
}

class FakePreferencesRepository implements PreferencesRepository {
  AppPreferences stored = const AppPreferences();

  @override
  Future<AppPreferences> read() async => stored;

  @override
  Future<void> saveTheme(ThemePreference theme) async =>
      stored = stored.copyWith(theme: theme);

  @override
  Future<void> saveDefaultSort(EventSort sort) async =>
      stored = stored.copyWith(defaultSort: sort);
}
