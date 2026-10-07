import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'config/firebase_config.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'state/display_preferences.dart';
import 'state/registration_cart.dart';
import 'storage/app_storage.dart';
import 'storage/draft_repository.dart';
import 'storage/preferences_store.dart';

Future<void> main() async {
  // TP 6 : nécessaire pour que `DateFormat.yMMMEd('fr_FR')` (récapitulatif,
  // sélecteur de plage de dates) dispose des données de locale françaises.
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  // TP 7 : `await` avant `runApp`, pas un `FutureBuilder` racine — choix
  // retenu par cohérence avec l'initialisation d'intl ci-dessus, déjà de ce
  // style dans ce fichier (éviter de mélanger les deux approches pour une
  // même fonction `main`). Les accesseurs synchrones de `prefsStore` ne
  // doivent jamais être appelés avant que ce `Future` soit résolu.
  await prefsStore.init();
  // TP 8 : l'échec d'initialisation de Firebase est géré — l'application
  // démarre alors sur un écran d'erreur explicite (avec « Réessayer ») au
  // lieu de laisser une exception non interceptée dans le widget racine.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (useEmulators) {
      // Partie D : avant tout autre appel Auth / Firestore.
      await FirebaseAuth.instance
          .useAuthEmulator(emulatorHost, authEmulatorPort);
      FirebaseFirestore.instance
          .useFirestoreEmulator(emulatorHost, firestoreEmulatorPort);
    }
  } catch (e) {
    runApp(FirebaseInitErrorApp(error: e, onRetry: main));
    return;
  }
  // TP 7, partie C.4 : politique de purge déclenchée au lancement de
  // l'application — pas de tâche planifiée en arrière-plan à mettre en
  // place pour ce TP, et le répertoire temporaire n'est de toute façon
  // consulté qu'à ce moment-là par cette application (voir README). Ne
  // bloque pas l'affichage : lancé sans `await`.
  unawaited(_purgeTemporaryFiles());
  runApp(
    // Un unique MultiProvider au-dessus de MaterialApp (TP 4) : les deux
    // notifiers vivent au-dessus du Navigator, donc l'état survit à toute
    // navigation — y compris entre les Navigator imbriqués des onglets
    // (TP 3, Partie D) — et reste partagé entre tous les écrans.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistrationCart()),
        ChangeNotifierProvider(create: (_) => DisplayPreferences()),
      ],
      child: const EventPlannerFormsApp(),
    ),
  );
}

/// Supprime, dans le répertoire temporaire, les fichiers de plus de 7 jours
/// (voir [purgeDirectory] et la justification du déclenchement en README).
Future<void> _purgeTemporaryFiles() async {
  final tempDir = await getTemporaryDirectory();
  await purgeDirectory(tempDir, maxAge: const Duration(days: 7));
}

class EventPlannerFormsApp extends StatelessWidget {
  const EventPlannerFormsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lu une seule fois au démarrage (pas de Provider pour cette valeur,
    // hors périmètre du TP 7) : un changement de thème dans les réglages
    // s'appliquera au prochain lancement, pas en direct dans cette session
    // — la persistance elle-même, elle, est vérifiée immédiatement (voir
    // README, partie A).
    final themeMode = prefsStore.themeMode == AppThemeMode.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    return MaterialApp(
      title: 'Event Planner',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,
      initialRoute: AppRoutes.home,
      onGenerateRoute: RouteGenerator.generateRoute,
      onUnknownRoute: RouteGenerator.unknownRoute,
    );
  }
}

/// Écran affiché si `Firebase.initializeApp` échoue (TP 8, partie A).
class FirebaseInitErrorApp extends StatelessWidget {
  const FirebaseInitErrorApp({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Planner',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Impossible de démarrer Firebase',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'La configuration Firebase est absente ou incomplète '
                    "(plateforme non configurée avec `flutterfire configure`, "
                    'fichier google-services.json manquant…). '
                    "L'application ne peut pas continuer sans elle.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Détail technique : ${error.runtimeType}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
