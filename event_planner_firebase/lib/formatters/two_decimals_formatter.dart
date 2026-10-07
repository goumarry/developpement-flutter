import 'package:flutter/services.dart';

/// Limite la saisie du champ tarif à deux décimales maximum après le
/// séparateur (`.` ou `,`), sans jamais bloquer la saisie de la partie
/// entière. Une frappe qui produirait une troisième décimale est rejetée :
/// on renvoie [oldValue] inchangé plutôt que de tronquer, pour ne pas
/// déplacer le curseur de façon surprenante.
class TwoDecimalsFormatter extends TextInputFormatter {
  static final RegExp _upToTwoDecimals = RegExp(r'^\d*([.,]\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    if (_upToTwoDecimals.hasMatch(newValue.text)) return newValue;
    return oldValue;
  }
}
