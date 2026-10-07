/// Conditions réseau simulées, pour **démontrer** latence et panne sans
/// dépendre d'une vraie coupure (réglages > « Démonstration réseau »).
enum NetworkDemoMode {
  normal('Normal', 'Appels réels, sans modification.'),
  slow('Latence 3 s', 'Ajoute ?delay=3000 à chaque appel du catalogue.'),
  serverError('Erreur 500', 'Remplace chaque appel par /http/500.');

  const NetworkDemoMode(this.label, this.description);
  final String label;
  final String description;
}
