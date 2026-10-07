import 'package:flutter/material.dart';

/// Thème **unique** de l'application, clair et sombre.
///
/// Toute couleur vient d'ici : le `ColorScheme` dérivé de [_seed] et
/// l'extension [AppStatusColors] pour les couleurs d'état que Material ne
/// fournit pas (succès, avertissement). Aucun `Colors.xxx` ni `Color(0x…)`
/// ailleurs dans `lib/`.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF3F51B5);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Accessibilité : zones tactiles d'au moins 48 dp sur tous les
      // contrôles Material, et pas de densité « compacte » qui les réduirait.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      extensions: [
        isDark
            ? const AppStatusColors(
                success: Color(0xFF81C995),
                warningContainer: Color(0xFF5C4300),
                onWarningContainer: Color(0xFFFFDF9E),
              )
            : const AppStatusColors(
                success: Color(0xFF1E7B3C),
                warningContainer: Color(0xFFFFE8B0),
                onWarningContainer: Color(0xFF4A3400),
              ),
      ],
    );
  }
}

/// Couleurs d'état absentes du `ColorScheme` Material.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  /// Raccourci : `AppStatusColors.of(context).success`.
  static AppStatusColors of(BuildContext context) =>
      Theme.of(context).extension<AppStatusColors>()!;

  /// Jauge d'un événement où il reste de la place.
  final Color success;

  /// Fond et texte du bandeau « données non fraîches ».
  final Color warningContainer;
  final Color onWarningContainer;

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? warningContainer,
    Color? onWarningContainer,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    );
  }

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other == null) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
    );
  }
}
