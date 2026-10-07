import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/firebase/firebase_auth_service.dart';
import 'data/firebase/firebase_options.dart';
import 'data/firebase/firestore_event_repository.dart';
import 'data/firebase/firestore_registration_repository.dart';
import 'data/local/file_catalog_cache.dart';
import 'data/local/shared_prefs_repository.dart';
import 'data/remote/dummyjson_event_repository.dart';
import 'data/remote/http_client_provider.dart';
import 'domain/models/app_preferences.dart';
import 'presentation/app.dart';
import 'presentation/startup_error_app.dart';
import 'state/network_demo_state.dart';

/// Point d'entrée et **racine de composition** : seul fichier qui choisit les
/// implémentations de `data/` et les injecte, sous forme d'interfaces du
/// domaine, dans la présentation.
///
/// Avant `runApp` : Firebase est initialisé et les préférences nécessaires au
/// premier rendu (thème) sont chargées — pas d'écran qui clignote du thème
/// clair au thème sombre.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Exception {
    runApp(const StartupErrorApp(onRetry: main));
    return;
  }
  final preferencesRepository = SharedPrefsRepository();
  final prefs = await AppPreferences.load(preferencesRepository);
  final networkDemo = NetworkDemoState();
  runApp(
    EventPlannerApp(
      initialPrefs: prefs,
      preferencesRepository: preferencesRepository,
      eventRepository: DummyJsonEventRepository(
        client: provideHttpClient(),
        demoMode: () => networkDemo.mode,
      ),
      catalogCache: FileCatalogCache(),
      authRepository: FirebaseAuthService(),
      organizerEventRepository: FirestoreEventRepository(),
      registrationRepository: FirestoreRegistrationRepository(),
      networkDemo: networkDemo,
    ),
  );
}
