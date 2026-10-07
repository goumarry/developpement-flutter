import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'state/display_preferences.dart';
import 'state/registration_cart.dart';
import 'storage/app_storage.dart';
import 'storage/draft_repository.dart';
import 'storage/preferences_store.dart';

void main() async {
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
