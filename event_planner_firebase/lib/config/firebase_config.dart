import 'package:flutter/foundation.dart';

/// Partie D : bascule vers les émulateurs Firebase locaux, sans dupliquer le
/// code. Activer avec `flutter run --dart-define=USE_EMULATORS=true`.
const bool useEmulators = bool.fromEnvironment('USE_EMULATORS');

/// Depuis l'émulateur Android, `localhost` désigne l'émulateur lui-même ;
/// l'hôte de la machine de développement est `10.0.2.2`.
String get emulatorHost =>
    (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? '10.0.2.2'
        : 'localhost';

const int authEmulatorPort = 9099;
const int firestoreEmulatorPort = 8080;
