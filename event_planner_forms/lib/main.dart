import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'state/display_preferences.dart';
import 'state/registration_cart.dart';

void main() async {
  // TP 6 : nécessaire pour que `DateFormat.yMMMEd('fr_FR')` (récapitulatif,
  // sélecteur de plage de dates) dispose des données de locale françaises.
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
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

class EventPlannerFormsApp extends StatelessWidget {
  const EventPlannerFormsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Planner',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      initialRoute: AppRoutes.home,
      onGenerateRoute: RouteGenerator.generateRoute,
      onUnknownRoute: RouteGenerator.unknownRoute,
    );
  }
}
