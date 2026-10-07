/// Règles de **validation croisée** du formulaire d'événement (séance 6) —
/// fonctions pures, aucun import Flutter. Chacune porte sur plusieurs champs
/// à la fois ; l'écran lui passe les valeurs courantes au moment de valider.
library;

/// L'adresse est obligatoire pour un événement en présentiel, et doit rester
/// vide pour un événement en ligne.
String? validateAddress({required String? address, required bool isOnline}) {
  final text = address?.trim() ?? '';
  if (isOnline) {
    return text.isEmpty
        ? null
        : "Videz l'adresse : un événement en ligne n'a pas de lieu physique.";
  }
  return text.isEmpty
      ? "Indiquez l'adresse du lieu, ou cochez « En ligne »."
      : null;
}

/// Le tarif doit être 0 (ou vide) si « Gratuit » est coché, positif sinon.
/// Cocher la case ne corrige jamais la saisie : cette règle refuse
/// l'incohérence et dit comment la lever.
String? validatePrice({required String? priceText, required bool isFree}) {
  final text = (priceText?.trim() ?? '').replaceAll(',', '.');
  if (text.isEmpty) {
    return isFree ? null : 'Indiquez un tarif, ou cochez « Gratuit ».';
  }
  final value = double.tryParse(text);
  if (value == null) return 'Saisissez un tarif valide, par exemple 12.50.';
  if (value < 0) return 'Le tarif ne peut pas être négatif.';
  if (isFree && value != 0) {
    return 'Mettez le tarif à 0 ou décochez « Gratuit ».';
  }
  if (!isFree && value == 0) {
    return 'Un tarif de 0 correspond à un événement gratuit : cochez « Gratuit ».';
  }
  return null;
}

/// En modification, la capacité ne peut pas descendre sous le nombre de
/// places déjà attribuées.
String? validateCapacityAgainstExisting({
  required String? capacityText,
  required int existingRegistrations,
}) {
  final value = int.tryParse(capacityText?.trim() ?? '');
  if (value == null) return null; // vide ou non numérique : validateur de champ
  if (value < existingRegistrations) {
    return 'Gardez au moins $existingRegistrations place(s) : '
        'elles sont déjà attribuées.';
  }
  return null;
}

/// La fin doit être strictement postérieure au début.
String? validateDateRange(DateTime? start, DateTime? end) {
  if (start == null) return 'Choisissez la date de début.';
  if (end == null) return 'Choisissez la date de fin.';
  if (!end.isAfter(start)) {
    return 'La fin doit être après le début : choisissez une fin ultérieure.';
  }
  return null;
}
