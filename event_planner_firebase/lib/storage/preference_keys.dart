/// Clés de préférences déclarées une seule fois. Toute autre partie du code
/// référence ces constantes : aucune chaîne littérale de clé ailleurs.
class PreferenceKeys {
  const PreferenceKeys._();

  static const String themeMode = 'pref_theme_mode'; // défaut : 'light'
  static const String defaultSort = 'pref_default_sort'; // défaut : 'date'
  static const String defaultCategoryFilter =
      'pref_default_category'; // défaut : '' (aucun filtre)
  static const String displayDensity =
      'pref_display_density'; // défaut : 'comfortable'
  static const String lastScreen = 'pref_last_screen'; // défaut : 'home'

  static const Set<String> all = {
    themeMode,
    defaultSort,
    defaultCategoryFilter,
    displayDensity,
    lastScreen,
  };
}
