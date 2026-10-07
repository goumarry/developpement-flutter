// Les quatre états transverses (Partie B) : chacun a un rendu propre, et un
// écran affiche le bon selon la donnée injectée.
import 'package:event_planner_app/domain/failures.dart';
import 'package:event_planner_app/domain/models/catalog_snapshot.dart';
import 'package:event_planner_app/domain/models/user_profile.dart';
import 'package:event_planner_app/presentation/screens/catalog_screen.dart';
import 'package:event_planner_app/presentation/screens/my_registrations_screen.dart';
import 'package:event_planner_app/presentation/widgets/event_card.dart';
import 'package:event_planner_app/presentation/widgets/state_views.dart';
import 'package:event_planner_app/state/auth_state.dart';
import 'package:event_planner_app/state/catalog_state.dart';
import 'package:event_planner_app/state/registration_cart_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/fakes.dart';
import 'harness.dart';

void main() {
  group('Vues d\'état', () {
    testWidgets('ErrorView : message et reprise', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        testApp(ErrorView(message: 'Serveur en panne', onRetry: () => retries++)),
      );

      expect(find.text('Serveur en panne'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      expect(retries, 1);
    });

    testWidgets('SignInRequiredView : distingue la session expirée',
        (tester) async {
      await tester.pumpWidget(
        testApp(SignInRequiredView(reason: 'Pour continuer.', onSignIn: () {})),
      );
      expect(find.text('Connexion requise'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);

      await tester.pumpWidget(
        testApp(
          SignInRequiredView(
            reason: 'Pour continuer.',
            onSignIn: () {},
            sessionExpired: true,
          ),
        ),
      );
      expect(find.text('Session expirée'), findsOneWidget);
      expect(find.text('Se reconnecter'), findsOneWidget);
    });

    testWidgets('aucun débordement sur un très petit écran', (tester) async {
      tester.view.physicalSize = const Size(240, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        testApp(
          const EmptyView(
            title: 'Aucune inscription',
            message: 'Un message d\'explication assez long pour ne pas tenir '
                'sur un écran aussi petit sans défilement.',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('CatalogScreen affiche l\'état correspondant à la donnée injectée', () {
    late FakeEventRepository repository;
    late FakeCatalogCache cache;
    late CatalogState catalog;

    setUp(() {
      repository = FakeEventRepository(events: [buildEvent(title: 'Salon')]);
      cache = FakeCatalogCache();
      catalog = CatalogState(repository: repository, cache: cache);
    });

    Future<void> pumpCatalog(WidgetTester tester) async {
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider.value(
            value: catalog,
            child: const CatalogScreen(),
          ),
          scaffold: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300)); // fondu d'état
    }

    testWidgets('chargement', (tester) async {
      await pumpCatalog(tester); // aucun chargement terminé
      expect(find.byType(LoadingView), findsOneWidget);
    });

    testWidgets('données', (tester) async {
      await catalog.loadFirstPage();
      await pumpCatalog(tester);
      expect(find.byType(EventCard), findsOneWidget);
      expect(find.text('Salon'), findsOneWidget);
    });

    testWidgets('recherche sans résultat : vue vide, pas vue d\'erreur',
        (tester) async {
      await catalog.loadFirstPage(query: 'introuvable');
      await pumpCatalog(tester);
      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text('Aucun résultat'), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('erreur serveur sans copie locale : vue d\'erreur',
        (tester) async {
      repository.failure = const ServerFailure(500);
      await catalog.loadFirstPage();
      await pumpCatalog(tester);
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.byType(EmptyView), findsNothing);
    });

    testWidgets('mode dégradé : la copie locale et le bandeau « pas frais »',
        (tester) async {
      cache.snapshot = CatalogSnapshot(
        events: [buildEvent(title: 'En cache')],
        total: 1,
        savedAt: DateTime(2026, 10, 7, 14, 30),
      );
      repository.failure = const NetworkFailure();
      await catalog.loadFirstPage();
      await pumpCatalog(tester);

      expect(find.text('En cache'), findsOneWidget);
      expect(find.textContaining('Hors connexion'), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
    });
  });

  group('Écran exigeant une identité', () {
    testWidgets('non connecté puis session expirée', (tester) async {
      final authRepository = FakeAuthRepository();
      final auth = AuthState(repository: authRepository);
      final cart =
          RegistrationCartState(repository: FakeRegistrationRepository());
      addTearDown(auth.dispose);
      addTearDown(cart.dispose);

      await tester.pumpWidget(
        testApp(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: auth),
              ChangeNotifierProvider.value(value: cart),
            ],
            child: const MyRegistrationsScreen(),
          ),
          scaffold: false,
        ),
      );

      authRepository.emit(null);
      await tester.pump();
      await tester.pump();
      expect(find.text('Connexion requise'), findsOneWidget);

      authRepository.emit(const UserProfile(uid: 'u', email: 'a@b.fr'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(SignInRequiredView), findsNothing);

      authRepository.emit(null); // fin de session non demandée
      await tester.pump();
      await tester.pump();
      expect(find.text('Session expirée'), findsOneWidget);
    });
  });
}
