/// Formule de participation à un événement.
///
/// Données **codées en dur** (voir `lib/data/sample_packages.dart`). C'est le
/// type qui voyage dans la *valeur de retour* de `Navigator.pop` depuis l'écran
/// de sélection vers l'écran de détail : le `Future` attendu côté détail est
/// donc explicitement typé `Future<Formule?>`.
class Formule {
  const Formule({
    required this.id,
    required this.label,
    required this.priceEur,
    required this.description,
  });

  final String id;
  final String label;
  final int priceEur;
  final String description;

  String get priceLabel => priceEur == 0 ? 'Gratuit' : '$priceEur €';
}
