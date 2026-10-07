// La règle de dépendance entre couches, rendue **vérifiable** : ce test lit
// les `import` de chaque fichier de `lib/` et échoue à la première violation.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pour chaque couche, les motifs d'import interdits.
const Map<String, List<String>> forbiddenImports = {
  // Le domaine ne connaît ni Flutter ni les autres couches.
  'domain': [
    'package:flutter/',
    'data/',
    'state/',
    'presentation/',
    'package:http/',
    'package:cloud_firestore/',
    'package:firebase_',
    'package:shared_preferences/',
    'package:provider/',
  ],
  // Les données implémentent le domaine : aucun widget, aucun état.
  'data': [
    'package:flutter/material.dart',
    'package:flutter/widgets.dart',
    'package:flutter/cupertino.dart',
    'presentation/',
    'state/',
    'package:provider/',
  ],
  // L'état ne dépend que du domaine (et de `foundation` pour ChangeNotifier).
  'state': [
    'package:flutter/material.dart',
    'package:flutter/widgets.dart',
    'package:flutter/cupertino.dart',
    'data/',
    'presentation/',
    'package:http/',
    'package:cloud_firestore/',
    'package:firebase_',
    'package:shared_preferences/',
  ],
  // La présentation passe par l'état et le domaine, jamais par les données.
  'presentation': [
    'data/',
    'package:http/',
    'package:cloud_firestore/',
    'package:firebase_',
    'package:shared_preferences/',
  ],
};

final RegExp _import = RegExp(r'''^import\s+['"]([^'"]+)['"]''');

void main() {
  for (final layer in forbiddenImports.keys) {
    test('lib/$layer ne franchit pas la règle de dépendance', () {
      final files = Directory('lib/$layer')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      expect(files, isNotEmpty, reason: 'la couche $layer existe');

      final violations = <String>[];
      for (final file in files) {
        for (final line in file.readAsLinesSync()) {
          final uri = _import.firstMatch(line.trim())?.group(1);
          if (uri == null) continue;
          for (final forbidden in forbiddenImports[layer]!) {
            // Un import relatif vers une autre couche remonte toujours par
            // `../` ; un import interne à la couche ne contient pas ce motif.
            final crossesLayer =
                forbidden.endsWith('/') &&
                !forbidden.startsWith('package:') &&
                uri.contains('../$forbidden');
            if (crossesLayer || uri.startsWith(forbidden)) {
              violations.add('${file.path} importe $uri');
            }
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  }
}
