import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/app_preferences.dart';
import '../domain/repositories/event_repository.dart';
import '../state/catalog_state.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

/// Widget racine. Reçoit des **interfaces** du domaine : il ignore quelles
/// implémentations (`data/`) `main()` a choisies.
class EventPlannerApp extends StatelessWidget {
  const EventPlannerApp({
    super.key,
    required this.initialPrefs,
    required this.eventRepository,
  });

  final AppPreferences initialPrefs;
  final EventRepository eventRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CatalogState(repository: eventRepository)..load(),
      child: MaterialApp(
        title: 'Event Planner',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: switch (initialPrefs.theme) {
          ThemePreference.system => ThemeMode.system,
          ThemePreference.light => ThemeMode.light,
          ThemePreference.dark => ThemeMode.dark,
        },
        initialRoute: AppRoutes.catalog,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
