import 'package:flutter/widgets.dart';

/// Déclenche [onBackground] quand l'application quitte réellement le
/// premier plan (TP 7, partie B — sauvegarde automatique du brouillon en
/// cours d'édition).
///
/// Écoute [AppLifecycleState.paused], **pas** `inactive` : `inactive` est
/// émis très ponctuellement (ouverture du sélecteur multitâche, alerte
/// système, overlay d'appel entrant) sans que l'application ne quitte
/// vraiment le premier plan — écrire sur disque à chaque occurrence serait
/// à la fois trop fréquent et pas représentatif d'un réel "passage en
/// arrière-plan". `paused` signale que l'application n'est plus du tout
/// visible : c'est le moment pertinent pour persister.
class DraftLifecycleObserver extends WidgetsBindingObserver {
  DraftLifecycleObserver({required this.onBackground});

  final VoidCallback onBackground;

  void attach() => WidgetsBinding.instance.addObserver(this);
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      onBackground();
    }
  }
}
