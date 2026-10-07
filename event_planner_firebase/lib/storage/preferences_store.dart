import 'package:shared_preferences/shared_preferences.dart';

import 'preference_keys.dart';

enum AppThemeMode { light, dark }

enum EventSortOrder { date, title, popularity }

enum DisplayDensity { comfortable, compact }

/// Interface métier des préférences — **aucun écran n'appelle
/// `shared_preferences` directement**, uniquement cette abstraction.
abstract class PreferencesStore {
  Future<void> init();

  AppThemeMode get themeMode;
  Future<void> setThemeMode(AppThemeMode mode);

  EventSortOrder get defaultSort;
  Future<void> setDefaultSort(EventSortOrder order);

  String get defaultCategoryFilter; // '' = aucun filtre
  Future<void> setDefaultCategoryFilter(String category);

  DisplayDensity get displayDensity;
  Future<void> setDisplayDensity(DisplayDensity density);

  String get lastScreen;
  Future<void> setLastScreen(String screenName);
}

/// Implémentation sur `SharedPreferencesWithCache` (voir justification dans
/// le README — en bref : l'interface ci-dessus expose des accesseurs
/// **synchrones**, ce que seule cette API fournit après initialisation ;
/// `SharedPreferencesAsync` aurait forcé soit un type `Future` sur chaque
/// `get`, soit un cache maison redondant avec celui que l'API offre déjà).
///
/// **Contrat important** : les accesseurs synchrones (`themeMode`,
/// `defaultSort`, ...) supposent que [init] a déjà été appelée et que son
/// `Future` est résolu. Les appeler avant est une erreur de programmation
/// (ils lèveront une exception sur le cache non initialisé) — c'est
/// pourquoi `main()` attend [init] avant tout `runApp`.
class SharedPreferencesStore implements PreferencesStore {
  SharedPreferencesWithCache? _prefs;

  SharedPreferencesWithCache get _cache {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'PreferencesStore.init() doit être appelée et attendue avant tout '
        'accès synchrone.',
      );
    }
    return prefs;
  }

  @override
  Future<void> init() async {
    _prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: PreferenceKeys.all,
      ),
    );
  }

  @override
  AppThemeMode get themeMode {
    final raw = _cache.getString(PreferenceKeys.themeMode) ?? 'light';
    return raw == 'dark' ? AppThemeMode.dark : AppThemeMode.light;
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) =>
      _cache.setString(PreferenceKeys.themeMode, mode.name);

  @override
  EventSortOrder get defaultSort {
    final raw = _cache.getString(PreferenceKeys.defaultSort) ?? 'date';
    return EventSortOrder.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => EventSortOrder.date,
    );
  }

  @override
  Future<void> setDefaultSort(EventSortOrder order) =>
      _cache.setString(PreferenceKeys.defaultSort, order.name);

  @override
  String get defaultCategoryFilter =>
      _cache.getString(PreferenceKeys.defaultCategoryFilter) ?? '';

  @override
  Future<void> setDefaultCategoryFilter(String category) =>
      _cache.setString(PreferenceKeys.defaultCategoryFilter, category);

  @override
  DisplayDensity get displayDensity {
    final raw =
        _cache.getString(PreferenceKeys.displayDensity) ?? 'comfortable';
    return raw == 'compact' ? DisplayDensity.compact : DisplayDensity.comfortable;
  }

  @override
  Future<void> setDisplayDensity(DisplayDensity density) =>
      _cache.setString(PreferenceKeys.displayDensity, density.name);

  @override
  String get lastScreen =>
      _cache.getString(PreferenceKeys.lastScreen) ?? 'home';

  @override
  Future<void> setLastScreen(String screenName) =>
      _cache.setString(PreferenceKeys.lastScreen, screenName);
}
