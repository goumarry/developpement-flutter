import 'package:event_planner_app/domain/models/user_profile.dart';
import 'package:event_planner_app/state/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  const user = UserProfile(uid: 'uid-1', email: 'ada@example.org');
  late FakeAuthRepository repository;
  late AuthState auth;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    repository = FakeAuthRepository();
    auth = AuthState(repository: repository);
  });

  tearDown(() => auth.dispose());

  test('état inconnu tant que la session n\'est pas restaurée', () {
    expect(auth.status, AuthStatus.unknown);
  });

  test(
    'une session qui prend fin toute seule est signalée comme expirée',
    () async {
      repository.emit(user);
      await settle();
      expect(auth.isSignedIn, isTrue);

      repository.emit(null); // révocation côté serveur, sans signOut()
      await settle();

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
    },
  );

  test('une déconnexion volontaire n\'est pas une session expirée', () async {
    repository.emit(user);
    await settle();

    await auth.signOut();
    await settle();

    expect(auth.status, AuthStatus.signedOut);
    expect(auth.sessionExpired, isFalse);
  });
}
