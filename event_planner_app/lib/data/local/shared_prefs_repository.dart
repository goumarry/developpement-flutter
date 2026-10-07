import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_preferences.dart';
import '../../domain/repositories/preferences_repository.dart';

/// Préférences sur `SharedPreferencesAsync`.
///
/// Choix de l'API asynchrone (plutôt que `SharedPreferencesWithCache`) :
/// les préférences sont lues **une seule fois**, dans `main()` avant
/// `runApp`, puis vivent en mémoire dans `PreferencesState`. Un cache
/// synchrone supplémentaire ferait doublon avec cet état.
///
/// Les clés ne sont déclarées qu'ici ; une valeur inconnue ou absente retombe
/// sur la valeur par défaut au lieu de faire échouer la lecture.
class SharedPrefsRepository implements PreferencesRepository {
  SharedPrefsRepository({SharedPreferencesAsync? preferences})
      : _prefs = preferences ?? SharedPreferencesAsync();

  static const String _themeKey = 'pref_theme';
  static const String _sortKey = 'pref_default_sort';

  final SharedPreferencesAsync _prefs;

  @override
  Future<AppPreferences> read() async {
    final theme = await _prefs.getString(_themeKey);
    final sort = await _prefs.getString(_sortKey);
    return AppPreferences(
      theme: ThemePreference.values.firstWhere(
        (value) => value.name == theme,
        orElse: () => ThemePreference.system,
      ),
      defaultSort: EventSort.values.firstWhere(
        (value) => value.name == sort,
        orElse: () => EventSort.date,
      ),
    );
  }

  @override
  Future<void> saveTheme(ThemePreference theme) =>
      _prefs.setString(_themeKey, theme.name);

  @override
  Future<void> saveDefaultSort(EventSort sort) =>
      _prefs.setString(_sortKey, sort.name);
}
