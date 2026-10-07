// Règles de validation des formulaires (séance 6), dont les validations
// croisées. Fonctions pures : testées sans aucun widget.
import 'package:event_planner_app/domain/rules/event_form_rules.dart';
import 'package:event_planner_app/domain/rules/registration_form_rules.dart';
import 'package:event_planner_app/domain/rules/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formulaire d\'inscription — validations croisées', () {
    test('confirmation du courriel : doit reproduire le courriel', () {
      expect(
        validateEmailConfirmation(
          email: 'ada@example.org',
          confirmation: ' ADA@example.org ',
        ),
        isNull,
        reason: 'casse et espaces de bord ignorés',
      );
      expect(
        validateEmailConfirmation(
          email: 'ada@example.org',
          confirmation: 'ada@exemple.org',
        ),
        isNotNull,
      );
      expect(
        validateEmailConfirmation(email: 'ada@example.org', confirmation: ''),
        isNotNull,
      );
    });

    test('places : bornées par les places restantes de l\'événement', () {
      expect(validateSeats(seatsText: '2', remainingSeats: 2), isNull);
      expect(validateSeats(seatsText: '3', remainingSeats: 2), isNotNull);
      expect(validateSeats(seatsText: '1', remainingSeats: 0), isNotNull);
    });

    test('places : entier positif, plafonné par inscription', () {
      expect(validateSeats(seatsText: '', remainingSeats: 50), isNotNull);
      expect(validateSeats(seatsText: '0', remainingSeats: 50), isNotNull);
      expect(validateSeats(seatsText: 'deux', remainingSeats: 50), isNotNull);
      expect(
        validateSeats(
          seatsText: '${maxSeatsPerRegistration + 1}',
          remainingSeats: 50,
        ),
        isNotNull,
      );
      expect(
        validateSeats(
          seatsText: '$maxSeatsPerRegistration',
          remainingSeats: 50,
        ),
        isNull,
      );
    });
  });

  group('Formulaire d\'événement — validations croisées', () {
    test('adresse : obligatoire en présentiel, interdite en ligne', () {
      expect(validateAddress(address: '', isOnline: false), isNotNull);
      expect(validateAddress(address: '1 rue X', isOnline: false), isNull);
      expect(validateAddress(address: '', isOnline: true), isNull);
      expect(validateAddress(address: '1 rue X', isOnline: true), isNotNull);
    });

    test('tarif : cohérent avec la case « Gratuit »', () {
      expect(validatePrice(priceText: '', isFree: true), isNull);
      expect(validatePrice(priceText: '0', isFree: true), isNull);
      expect(validatePrice(priceText: '12,50', isFree: true), isNotNull);
      expect(validatePrice(priceText: '12,50', isFree: false), isNull);
      expect(validatePrice(priceText: '', isFree: false), isNotNull);
      expect(validatePrice(priceText: '0', isFree: false), isNotNull);
      expect(validatePrice(priceText: 'abc', isFree: false), isNotNull);
    });

    test('dates : la fin doit être strictement après le début', () {
      final start = DateTime(2026, 11, 2, 9);
      expect(validateDateRange(start, DateTime(2026, 11, 2, 11)), isNull);
      expect(validateDateRange(start, start), isNotNull);
      expect(validateDateRange(start, DateTime(2026, 11, 1)), isNotNull);
      expect(validateDateRange(null, start), isNotNull);
      expect(validateDateRange(start, null), isNotNull);
    });

    test('capacité : jamais sous les places déjà attribuées', () {
      expect(
        validateCapacityAgainstExisting(
          capacityText: '5',
          existingRegistrations: 5,
        ),
        isNull,
      );
      expect(
        validateCapacityAgainstExisting(
          capacityText: '4',
          existingRegistrations: 5,
        ),
        isNotNull,
      );
    });
  });

  group('Validateurs de champ', () {
    test('compose renvoie le premier message dans l\'ordre', () {
      final validator = compose([requiredField(), minLength(3)]);
      expect(validator(''), 'Ce champ est obligatoire.');
      expect(validator('ab'), contains('3'));
      expect(validator('abc'), isNull);
    });

    test('email accepte une adresse bien formée et rejette le reste', () {
      final validator = email();
      expect(validator('ada@example.org'), isNull);
      expect(validator('ada@example'), isNotNull);
      expect(validator('ada.example.org'), isNotNull);
    });
  });
}
