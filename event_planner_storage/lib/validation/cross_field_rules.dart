/// Règles de validation croisée du formulaire de création d'événement —
/// **aucun import de `package:flutter/*` ici** (même contrainte que
/// `validators.dart`). Ces règles portent sur plusieurs champs à la fois ;
/// elles ne peuvent pas s'exprimer dans un `validator` de champ isolé au sens
/// strict, mais chaque fonction reste pure et testable indépendamment de tout
/// widget. Les écrans leur passent les valeurs courantes (texte, booléens,
/// `DateTime`) au moment de la validation.
library;

/// L'adresse est obligatoire si l'événement n'est pas en ligne, et interdite
/// (doit rester vide) s'il est en ligne.
String? validateAddress({required String? address, required bool isOnline}) {
  final trimmed = address?.trim() ?? '';
  if (isOnline) {
    if (trimmed.isEmpty) return null;
    return "Videz l'adresse : l'événement est en ligne, aucun lieu physique "
        "n'est attendu.";
  }
  if (trimmed.isEmpty) {
    return "Indiquez l'adresse du lieu : l'événement n'est pas en ligne.";
  }
  return null;
}

/// Le tarif doit être nul (0 ou vide — convention retenue ici, voir README)
/// si « événement gratuit » est cochée. Cocher la case ne corrige jamais la
/// saisie automatiquement : c'est cette règle qui refuse l'incohérence.
String? validatePrice({required String? priceText, required bool isFree}) {
  final trimmed = priceText?.trim() ?? '';
  if (trimmed.isEmpty) return null; // champ vide : `required` gère ce cas
  final normalized = trimmed.replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null) {
    return 'Saisissez un tarif valide, par exemple 12.50.';
  }
  if (isFree && value != 0) {
    return "Mettez le tarif à 0 (ou videz le champ) : la case « gratuit » "
        'est cochée.';
  }
  if (value < 0) {
    return 'Le tarif ne peut pas être négatif.';
  }
  return null;
}

/// La capacité doit rester supérieure ou égale au nombre d'inscrits déjà
/// enregistrés pour l'événement (utile en modification d'un événement
/// partiellement rempli).
String? validateCapacityAgainstExisting({
  required String? capacityText,
  required int existingRegistrations,
}) {
  final trimmed = capacityText?.trim() ?? '';
  if (trimmed.isEmpty) return null; // champ vide : `required` gère ce cas
  final value = int.tryParse(trimmed);
  if (value == null) return null; // type déjà signalé par le validateur de champ
  if (value < existingRegistrations) {
    return 'Augmentez la capacité à au moins $existingRegistrations : '
        '$existingRegistrations participant(s) sont déjà inscrits.';
  }
  return null;
}

/// La date de fin doit être strictement postérieure à la date de début. Si
/// l'une des deux dates n'est pas encore renseignée, la règle ne peut pas
/// être évaluée : on le signale explicitement, sans lever d'exception.
String? validateDateRange(DateTime? start, DateTime? end) {
  if (start == null) return 'Choisissez la date de début.';
  if (end == null) return 'Choisissez la date de fin.';
  if (!end.isAfter(start)) {
    return 'La date de fin doit être après la date de début — choisissez '
        'une date de fin ultérieure.';
  }
  return null;
}
