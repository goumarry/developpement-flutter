import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../../domain/failures.dart';
import '../../domain/models/write_status.dart';

/// Traduit une erreur Firestore en `AppFailure`. Le message brut de
/// l'exception (`e.message`) n'est jamais transmis aux couches supérieures.
AppFailure mapFirestoreError(Object error) {
  if (error is AppFailure) return error;
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return const PermissionFailure();
      case 'unauthenticated':
        return const PermissionFailure('Session expirée : reconnectez-vous.');
      case 'unavailable':
      case 'deadline-exceeded':
        return const NetworkFailure(
          'Serveur injoignable. Vérifiez votre connexion puis réessayez.',
        );
      case 'not-found':
        return const NotFoundFailure();
    }
  }
  return const UnknownFailure();
}

/// Attend la confirmation serveur d'une écriture Firestore, au plus
/// [ackTimeout].
///
/// Hors connexion, le `Future` d'une écriture ne se résout pas : le SDK
/// l'applique à son cache local et la mettra en file. On cesse donc d'attendre
/// après [ackTimeout] et on renvoie [WriteStatus.queuedOffline], au lieu de
/// figer l'écran. Un refus des règles, lui, arrive vite et sort en
/// `AppFailure`.
Future<WriteStatus> awaitWrite(
  Future<void> write, {
  Duration ackTimeout = const Duration(seconds: 4),
}) async {
  try {
    await write.timeout(ackTimeout);
    return WriteStatus.confirmed;
  } on TimeoutException {
    return WriteStatus.queuedOffline;
  } on Exception catch (error) {
    throw mapFirestoreError(error);
  }
}
