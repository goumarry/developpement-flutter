import '../repositories/preferences_repository.dart';

/// Thème choisi par l'utilisateur. Type du domaine : `ThemeMode` appartient à
/// Flutter, la conversion se fait dans `presentation/`.
enum ThemePreference {
  system('Système'),
  light('Clair'),
  dark('Sombre');

  const ThemePreference(this.label);
  final String label;
}

/// Critère de tri du catalogue.
enum EventSort {
  date('Date'),
  title('Titre'),
  remainingSeats('Places restantes');

  const EventSort(this.label);
  final String label;
}

/// Préférences utilisateur persistées entre deux lancements — immuables.
class AppPreferences {
  const AppPreferences({
    this.theme = ThemePreference.system,
    this.defaultSort = EventSort.date,
  });

  /// Lit les préférences avant le premier rendu (appelé par `main()`). Un
  /// stockage illisible ne doit pas empêcher l'application de démarrer : on
  /// retombe alors sur les valeurs par défaut.
  static Future<AppPreferences> load(PreferencesRepository repository) async {
    try {
      return await repository.read();
    } on Exception {
      return const AppPreferences();
    }
  }

  final ThemePreference theme;
  final EventSort defaultSort;

  AppPreferences copyWith({ThemePreference? theme, EventSort? defaultSort}) {
    return AppPreferences(
      theme: theme ?? this.theme,
      defaultSort: defaultSort ?? this.defaultSort,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPreferences &&
          other.theme == theme &&
          other.defaultSort == defaultSort;

  @override
  int get hashCode => Object.hash(theme, defaultSort);
}
