import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/models/catalog_snapshot.dart';
import '../../domain/repositories/catalog_cache.dart';

/// Copie du dernier catalogue dans un fichier JSON du répertoire de support
/// de l'application.
///
/// Répertoire de *support* et non de *cache* : le système peut vider le cache
/// à tout moment, or ce fichier est précisément ce qui doit survivre pour le
/// mode hors connexion. Ce n'est pas non plus un document de l'utilisateur
/// (donc pas `getApplicationDocumentsDirectory`).
class FileCatalogCache implements CatalogCache {
  FileCatalogCache({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  static const String _fileName = 'catalog_snapshot.json';

  /// Injectable : les tests passent un répertoire temporaire.
  final Future<Directory> Function() _directory;

  Future<File> _file() async {
    final dir = await _directory();
    return File('${dir.path}/$_fileName');
  }

  @override
  Future<CatalogSnapshot?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      return CatalogSnapshot.fromJson(decoded);
    } on FormatException {
      return null; // fichier corrompu : comme s'il n'existait pas
    } on FileSystemException {
      return null;
    }
  }

  /// Écriture atomique : fichier temporaire puis renommage. Si l'application
  /// est tuée au milieu, le fichier final garde l'ancienne version intacte.
  @override
  Future<void> write(CatalogSnapshot snapshot) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(snapshot.toJson()), flush: true);
    await tmp.rename(file.path);
  }
}
