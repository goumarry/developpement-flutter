import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/firebase/firebase_options.dart';
import 'data/local/shared_prefs_repository.dart';
import 'data/remote/dummyjson_event_repository.dart';
import 'data/remote/http_client_provider.dart';
import 'domain/models/app_preferences.dart';
import 'presentation/app.dart';

/// Point d'entrée et **racine de composition** : seul fichier qui choisit les
/// implémentations de `data/` et les injecte, sous forme d'interfaces du
/// domaine, dans la présentation.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await AppPreferences.load(SharedPrefsRepository());
  final httpClients = SharedHttpClient();
  runApp(
    EventPlannerApp(
      initialPrefs: prefs,
      eventRepository: DummyJsonEventRepository(client: httpClients.client),
    ),
  );
}
