/// Règles de **validation croisée** du formulaire d'inscription — fonctions
/// pures, aucun import Flutter.
library;

/// Plafond de places pour une même inscription.
const int maxSeatsPerRegistration = 6;

/// Le courriel de confirmation doit reproduire le courriel saisi (comparaison
/// insensible à la casse et aux espaces de bord).
String? validateEmailConfirmation({
  required String? email,
  required String? confirmation,
}) {
  final typed = confirmation?.trim().toLowerCase() ?? '';
  if (typed.isEmpty) return 'Confirmez votre adresse courriel.';
  if (typed != (email?.trim().toLowerCase() ?? '')) {
    return 'Les deux adresses ne correspondent pas : corrigez l’une des deux.';
  }
  return null;
}

/// Le nombre de places dépend d'une donnée extérieure au champ : les places
/// encore disponibles pour l'événement.
String? validateSeats({
  required String? seatsText,
  required int remainingSeats,
}) {
  final text = seatsText?.trim() ?? '';
  if (text.isEmpty) return 'Indiquez le nombre de places.';
  final seats = int.tryParse(text);
  if (seats == null || seats < 1) {
    return 'Saisissez un nombre entier supérieur à 0.';
  }
  if (seats > maxSeatsPerRegistration) {
    return 'Au plus $maxSeatsPerRegistration places par inscription.';
  }
  if (remainingSeats <= 0) return 'Cet événement est complet.';
  if (seats > remainingSeats) {
    return 'Il ne reste que $remainingSeats place(s) : réduisez la demande.';
  }
  return null;
}
