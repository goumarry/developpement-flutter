import '../models/app_preferences.dart';

/// Persistance des préférences utilisateur.
abstract class PreferencesRepository {
  Future<AppPreferences> read();

  Future<void> saveTheme(ThemePreference theme);

  Future<void> saveDefaultSort(EventSort sort);
}
