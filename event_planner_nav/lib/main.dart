import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'routes/route_generator.dart';

void main() {
  runApp(const EventPlannerApp());
}

class EventPlannerApp extends StatelessWidget {
  const EventPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Planner',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      // Tout le routage est centralisé dans RouteGenerator :
      // - onGenerateRoute : route d'accueil + routes du parcours, avec
      //   validation explicite des arguments et écrans d'erreur ;
      // - onUnknownRoute : écran 404 générique pour tout nom non enregistré.
      initialRoute: AppRoutes.home,
      onGenerateRoute: RouteGenerator.generateRoute,
      onUnknownRoute: RouteGenerator.unknownRoute,
    );
  }
}
