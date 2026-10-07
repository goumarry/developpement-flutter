import '../domain/failures.dart';
import '../domain/models/write_status.dart';

/// Issue d'une action asynchrone déclenchée depuis un écran (enregistrer,
/// supprimer, confirmer…). Les états renvoient cette valeur au lieu de lever
/// une exception : l'écran n'a aucun `try/catch` à écrire, il lit le résultat.
class ActionResult {
  const ActionResult.success({this.queuedOffline = false}) : error = null;
  const ActionResult.failure(String this.error) : queuedOffline = false;

  factory ActionResult.fromWrite(WriteStatus status) =>
      ActionResult.success(queuedOffline: status == WriteStatus.queuedOffline);

  factory ActionResult.fromFailure(AppFailure failure) =>
      ActionResult.failure(failure.message);

  /// Message destiné à l'utilisateur, ou `null` si l'action a réussi.
  final String? error;

  /// L'action est acceptée localement mais pas encore confirmée par le
  /// serveur (hors connexion).
  final bool queuedOffline;

  bool get isSuccess => error == null;
}
