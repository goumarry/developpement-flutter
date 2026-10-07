import 'package:flutter/foundation.dart';

import '../domain/models/app_preferences.dart';
import '../domain/repositories/preferences_repository.dart';

/// Préférences de l'utilisateur : en mémoire pour l'affichage, écrites sur le
/// disque à chaque changement.
class PreferencesState extends ChangeNotifier {
  PreferencesState({required this._repository, required AppPreferences initial})
    : _preferences = initial;

  final PreferencesRepository _repository;
  AppPreferences _preferences;

  ThemePreference get theme => _preferences.theme;
  EventSort get defaultSort => _preferences.defaultSort;

  /// Applique le thème tout de suite, puis le persiste. Renvoie `false` si
  /// l'écriture a échoué : le choix vaut alors pour cette session seulement.
  Future<bool> setTheme(ThemePreference theme) async {
    if (theme == _preferences.theme) return true;
    _preferences = _preferences.copyWith(theme: theme);
    notifyListeners();
    return _persist(() => _repository.saveTheme(theme));
  }

  Future<bool> setDefaultSort(EventSort sort) async {
    if (sort == _preferences.defaultSort) return true;
    _preferences = _preferences.copyWith(defaultSort: sort);
    notifyListeners();
    return _persist(() => _repository.saveDefaultSort(sort));
  }

  Future<bool> _persist(Future<void> Function() write) async {
    try {
      await write();
      return true;
    } on Exception {
      return false;
    }
  }
}
