/// Couche de validation pure — **aucun import de `package:flutter/*` ici**.
/// Une [Validator] est une unité de responsabilité unique, combinable via
/// [compose]. Les widgets de formulaire n'appellent jamais de logique de
/// validation directement : ils passent uniquement le résultat de
/// `compose([...])` à leur `validator`.
typedef Validator = String? Function(String? value);

/// Champ obligatoire : rejette `null`, vide, ou blanc.
Validator required({String message = 'Ce champ est obligatoire.'}) {
  return (value) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  };
}

/// Longueur minimale. Ignore une valeur vide (laisse [required] gérer ce cas)
/// pour que les deux règles restent combinables sans message redondant.
Validator minLength(int min, {String Function(int min)? message}) {
  return (value) {
    final length = value?.trim().length ?? 0;
    if (length == 0) return null;
    if (length < min) {
      return (message ?? (m) => 'Doit contenir au moins $m caractères.')(min);
    }
    return null;
  };
}

/// Longueur maximale.
Validator maxLength(int max, {String Function(int max)? message}) {
  return (value) {
    final length = value?.trim().length ?? 0;
    if (length > max) {
      return (message ?? (m) => 'Ne doit pas dépasser $m caractères.')(max);
    }
    return null;
  };
}

/// Respect d'une expression régulière. Ignore une valeur vide (laisse
/// [required] gérer ce cas).
Validator matchesPattern(RegExp pattern, {required String message}) {
  return (value) {
    if (value == null || value.isEmpty) return null;
    return pattern.hasMatch(value) ? null : message;
  };
}

/// Entier strictement positif (places demandées, capacité...). Ignore une
/// valeur vide (laisse [required] gérer ce cas).
Validator positiveInteger({String message = 'Saisissez un nombre entier strictement positif.'}) {
  return (value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed <= 0) return message;
    return null;
  };
}

/// Exécute les validateurs dans l'ordre, retourne le premier message non nul.
Validator compose(List<Validator> validators) {
  return (value) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  };
}

/// Expression régulière d'adresse courriel, de forme générale (pas une
/// bibliothèque de validation externe), commentée morceau par morceau :
final RegExp emailPattern = RegExp(
  r'^[A-Za-z0-9._%+-]+' // partie locale : lettres, chiffres, points, _ % + -
  r'@' // arobase obligatoire, une seule fois
  r'[A-Za-z0-9.-]+' // nom de domaine : lettres, chiffres, points, tirets
  r'\.[A-Za-z]{2,}$', // extension : un point suivi d'au moins deux lettres
);

/// Validateur courriel prêt à l'emploi, construit sur [emailPattern].
Validator email({
  String message = 'Saisissez une adresse au format nom@domaine.ext',
}) =>
    matchesPattern(emailPattern, message: message);
