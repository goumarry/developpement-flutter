/// Validateurs de champ — fonctions pures, **aucun import Flutter**.
///
/// Un [Validator] porte une seule responsabilité ; [compose] les enchaîne. La
/// signature est celle attendue par `TextFormField.validator`, sans que ce
/// fichier dépende de Flutter : les formulaires ne contiennent aucune logique
/// de validation, ils branchent ces fonctions.
typedef Validator = String? Function(String? value);

/// Champ obligatoire : rejette `null`, vide ou blanc.
Validator requiredField({String message = 'Ce champ est obligatoire.'}) {
  return (value) => (value == null || value.trim().isEmpty) ? message : null;
}

/// Longueur minimale. Une valeur vide est laissée à [requiredField].
Validator minLength(int min) {
  return (value) {
    final length = value?.trim().length ?? 0;
    if (length == 0 || length >= min) return null;
    return 'Saisissez au moins $min caractères.';
  };
}

Validator maxLength(int max) {
  return (value) {
    final length = value?.trim().length ?? 0;
    return length > max ? 'Ne dépassez pas $max caractères.' : null;
  };
}

/// Entier strictement positif. Une valeur vide est laissée à [requiredField].
Validator positiveInteger({
  String message = 'Saisissez un nombre entier supérieur à 0.',
}) {
  return (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    return (parsed == null || parsed <= 0) ? message : null;
  };
}

/// Forme générale d'une adresse courriel : `local@domaine.ext`.
final RegExp _emailPattern = RegExp(
  r'^[A-Za-z0-9._%+-]+' // partie locale
  r'@'
  r'[A-Za-z0-9.-]+' // domaine
  r'\.[A-Za-z]{2,}$', // extension d'au moins deux lettres
);

/// Adresse courriel. Une valeur vide est laissée à [requiredField].
Validator email({
  String message = 'Saisissez une adresse au format nom@domaine.fr.',
}) {
  return (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return _emailPattern.hasMatch(text) ? null : message;
  };
}

/// Exécute les validateurs dans l'ordre et renvoie le premier message.
Validator compose(List<Validator> validators) {
  return (value) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  };
}
