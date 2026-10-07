/// Mise en forme des dates et des tarifs pour l'affichage, en français, sans
/// dépendance externe (fonctions pures).
library;

const List<String> _weekdays = [
  'lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.', //
];

const List<String> _months = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', //
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// `14h05`.
String timeLabel(DateTime date) => '${date.hour}h${_two(date.minute)}';

/// `ven. 12 juin 2026, 18h30`.
String dateLabel(DateTime date) =>
    '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]} '
    '${date.year}, ${timeLabel(date)}';

/// Même jour : `ven. 12 juin 2026, 18h30 – 20h30` ; sinon les deux dates.
String dateRangeLabel(DateTime start, DateTime end) {
  final sameDay =
      start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  return sameDay
      ? '${dateLabel(start)} – ${timeLabel(end)}'
      : '${dateLabel(start)} – ${dateLabel(end)}';
}

/// `Gratuit`, `12 €` ou `12,50 €`.
String priceLabel(double price) {
  if (price == 0) return 'Gratuit';
  final text = price == price.roundToDouble()
      ? price.toStringAsFixed(0)
      : price.toStringAsFixed(2).replaceAll('.', ',');
  return '$text €';
}
