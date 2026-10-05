import 'package:flutter/material.dart';

import '../state/registration_cart.dart';

/// Traduit un [CartOutcome] renvoyé par le notifier en message utilisateur.
/// C'est la **couche UI** qui décide comment présenter le signal — le notifier,
/// lui, ne connaît que l'énumération.
String cartOutcomeMessage(CartOutcome outcome) {
  return switch (outcome) {
    CartOutcome.added => 'Inscription ajoutée au panier.',
    CartOutcome.updated => 'Inscription mise à jour.',
    CartOutcome.removed => 'Inscription retirée du panier.',
    CartOutcome.rejectedDuplicate =>
      'Cet événement est déjà dans le panier — modifiez-le depuis le panier.',
    CartOutcome.rejectedEventFull =>
      'Impossible : l\'événement est complet.',
    CartOutcome.rejectedUserCap =>
      'Plafond atteint : ${RegistrationCart.maxSeatsPerUser} places maximum par personne.',
    CartOutcome.rejectedInvalidSeats => 'Nombre de places invalide.',
    CartOutcome.rejectedNotFound => 'Inscription introuvable.',
  };
}

/// Affiche le résultat d'une opération de panier via un [SnackBar].
void showCartOutcome(BuildContext context, CartOutcome outcome) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(cartOutcomeMessage(outcome)),
        backgroundColor: outcome.isSuccess ? null : Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
}
