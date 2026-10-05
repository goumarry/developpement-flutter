import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'state/display_preferences.dart';
import 'state/registration_cart.dart';

void main() {
  runApp(
    // Un unique MultiProvider au-dessus de MaterialApp : les deux notifiers
    // vivent au-dessus du Navigator, donc l'état survit à toute navigation et
    // reste partagé entre tous les écrans.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistrationCart()),
        ChangeNotifierProvider(create: (_) => DisplayPreferences()),
      ],
      child: const EventPlannerApp(),
    ),
  );
}

class EventPlannerApp extends StatelessWidget {
  const EventPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Planner — Panier',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      initialRoute: AppRoutes.home,
      onGenerateRoute: RouteGenerator.generateRoute,
      onUnknownRoute: RouteGenerator.unknownRoute,
    );
  }
}
