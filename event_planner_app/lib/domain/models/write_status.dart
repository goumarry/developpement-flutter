/// Issue d'une écriture distante acceptée.
enum WriteStatus {
  /// Le serveur a confirmé l'écriture.
  confirmed,

  /// Pas de réponse du serveur dans le délai : l'écriture est dans la file
  /// locale du SDK et partira au retour du réseau.
  queuedOffline,
}
