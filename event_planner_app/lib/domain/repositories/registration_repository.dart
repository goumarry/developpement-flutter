import '../models/registration.dart';
import '../models/write_status.dart';

/// Inscriptions confirmées d'un utilisateur.
abstract class RegistrationRepository {
  Stream<List<Registration>> watchConfirmed(String userId);

  /// Enregistre toutes les [registrations] ou aucune. Lève `PermissionFailure`
  /// si l'une existe déjà côté serveur (doublon) ou n'appartient pas à
  /// l'utilisateur connecté.
  Future<WriteStatus> confirmAll(List<Registration> registrations);

  Future<WriteStatus> cancel(String registrationId);
}
