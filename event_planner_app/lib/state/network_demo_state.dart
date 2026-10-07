import 'package:flutter/foundation.dart';

import '../domain/models/network_demo_mode.dart';

/// Mode de démonstration réseau choisi dans les réglages. Volontairement
/// **non persisté** : un « Erreur 500 » oublié ne doit pas survivre au
/// redémarrage de l'application.
class NetworkDemoState extends ChangeNotifier {
  NetworkDemoMode _mode = NetworkDemoMode.normal;

  NetworkDemoMode get mode => _mode;

  void setMode(NetworkDemoMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }
}
