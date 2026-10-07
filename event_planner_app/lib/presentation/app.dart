import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../domain/models/app_preferences.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/catalog_cache.dart';
import '../domain/repositories/event_repository.dart';
import '../domain/repositories/organizer_event_repository.dart';
import '../domain/repositories/preferences_repository.dart';
import '../domain/repositories/registration_repository.dart';
import '../state/auth_state.dart';
import '../state/catalog_state.dart';
import '../state/network_demo_state.dart';
import '../state/organizer_events_state.dart';
import '../state/preferences_state.dart';
import '../state/registration_cart_state.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

/// Widget racine. Ne reçoit que des **interfaces** du domaine : il ignore
/// quelles implémentations de `data/` ont été choisies par `main()`, et les
/// tests peuvent lui passer des doubles.
///
/// Un unique `MultiProvider` au-dessus de `MaterialApp` : les états vivent
/// au-dessus du `Navigator`, donc survivent à toute navigation et sont
/// partagés par tous les écrans.
class EventPlannerApp extends StatelessWidget {
  const EventPlannerApp({
    super.key,
    required this.initialPrefs,
    required this.preferencesRepository,
    required this.eventRepository,
    required this.catalogCache,
    required this.authRepository,
    required this.organizerEventRepository,
    required this.registrationRepository,
    required this.networkDemo,
  });

  final AppPreferences initialPrefs;
  final PreferencesRepository preferencesRepository;
  final EventRepository eventRepository;
  final CatalogCache catalogCache;
  final AuthRepository authRepository;
  final OrganizerEventRepository organizerEventRepository;
  final RegistrationRepository registrationRepository;

  /// Créé par `main()` car le dépôt du catalogue le lit aussi.
  final NetworkDemoState networkDemo;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: networkDemo),
        ChangeNotifierProvider(
          create: (_) => PreferencesState(
            repository: preferencesRepository,
            initial: initialPrefs,
          ),
        ),
        ChangeNotifierProvider(
          // Le tri de départ est la préférence persistée.
          create: (_) => CatalogState(
            repository: eventRepository,
            cache: catalogCache,
            initialSort: initialPrefs.defaultSort,
          )..loadFirstPage(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => AuthState(repository: authRepository),
        ),
        // Les deux états ci-dessous dépendent du compte connecté. Ils
        // s'abonnent à `AuthState` à leur création : chaque changement de
        // session leur est transmis par `bindUser`, hors de toute phase de
        // construction de widgets. `lazy: false` : l'abonnement existe dès le
        // lancement, pas seulement à la première ouverture de l'onglet.
        ChangeNotifierProvider(
          lazy: false,
          create: (context) {
            final auth = context.read<AuthState>();
            final cart = RegistrationCartState(
              repository: registrationRepository,
            );
            auth.addListener(() => cart.bindUser(auth.user?.uid));
            return cart;
          },
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) {
            final auth = context.read<AuthState>();
            final organizer = OrganizerEventsState(
              repository: organizerEventRepository,
            );
            auth.addListener(() => organizer.bindUser(auth.user?.uid));
            return organizer;
          },
        ),
      ],
      // `select` : seul un changement de thème reconstruit `MaterialApp`.
      builder: (context, _) {
        final theme = context.select<PreferencesState, ThemePreference>(
          (preferences) => preferences.theme,
        );
        return MaterialApp(
          title: 'Event Planner',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: switch (theme) {
            ThemePreference.system => ThemeMode.system,
            ThemePreference.light => ThemeMode.light,
            ThemePreference.dark => ThemeMode.dark,
          },
          // Composants Material en français (sélecteurs de date, infobulles,
          // libellés lus par les lecteurs d'écran).
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
