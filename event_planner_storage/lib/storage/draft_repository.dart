import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:path_provider/path_provider.dart';

import '../models/draft_record.dart';

/// Résumé d'un brouillon pour l'écran liste (TP 7, partie B) : juste assez
/// pour afficher une ligne, sans garder tout le modèle en mémoire.
class DraftSummary {
  const DraftSummary({
    required this.id,
    required this.title,
    required this.lastModified,
    required this.sizeBytes,
  });

  final String id;
  final String title;
  final DateTime lastModified;
  final int sizeBytes;
}

/// Levée par [DraftRepository.load] quand le fichier existe mais que son
/// contenu n'est pas un JSON valide — un cas **distinct** d'un brouillon
/// absent (qui, lui, renvoie `null` sans exception).
class DraftCorruptedException implements Exception {
  const DraftCorruptedException(this.id);
  final String id;
  @override
  String toString() => 'Brouillon illisible ($id)';
}

/// Accès disque aux brouillons — seul point du code qui touche `dart:io`
/// pour les brouillons (TP 7, partie B/C).
class DraftRepository {
  Directory? _draftsDir;

  /// Répertoire des brouillons, sous-dossier de
  /// `getApplicationDocumentsDirectory()`. Créé silencieusement s'il
  /// n'existe pas encore (cas limite "répertoire absent au premier accès") :
  /// aucune exception ne doit atteindre l'appelant pour ce cas, qui est
  /// systématique au tout premier lancement.
  Future<Directory> _directory() async {
    final existing = _draftsDir;
    if (existing != null) return existing;
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory('${documents.path}/drafts');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _draftsDir = dir;
    return dir;
  }

  /// Nom de fichier déterministe à partir de l'identifiant, et **sûr** :
  /// tout caractère hors `[A-Za-z0-9_-]` (donc `/`, `\`, et les deux points
  /// de `..`) est remplacé par `_`, ce qui exclut structurellement toute
  /// sortie du répertoire des brouillons via l'identifiant.
  String _safeFileName(String id) =>
      '${id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.json';

  Future<File> _fileFor(String id) async {
    final dir = await _directory();
    return File('${dir.path}/${_safeFileName(id)}');
  }

  /// `null` si l'identifiant est inconnu (fichier absent) — pas une erreur,
  /// l'appelant ouvre alors un brouillon vide. Un fichier présent mais vide
  /// (0 octet) est traité comme un brouillon vide, pas comme une erreur de
  /// parsing. Un contenu non-JSON lève [DraftCorruptedException].
  Future<DraftRecord?> load(String id) async {
    final file = await _fileFor(id);
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    if (content.trim().isEmpty) return DraftRecord.empty(id);
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return DraftRecord.fromJson(json);
    } on FormatException {
      throw DraftCorruptedException(id);
    }
  }

  /// Écriture atomique (TP 7, partie C.1) : le contenu est d'abord écrit
  /// dans un fichier temporaire distinct (`<id>.json.tmp`), puis ce fichier
  /// est renommé vers le nom final via [File.rename] — une opération
  /// atomique au niveau du système de fichiers. Si le processus est tué
  /// entre les deux étapes, le fichier final porte encore l'ancienne
  /// version intacte (ou n'existe pas encore) ; il n'existe aucun instant où
  /// il contient un contenu partiel.
  Future<void> save(DraftRecord draft) async {
    final dir = await _directory();
    final finalFile = File('${dir.path}/${_safeFileName(draft.id)}');
    final tmpFile = File('${dir.path}/${_safeFileName(draft.id)}.tmp');
    await tmpFile.writeAsString(jsonEncode(draft.toJson()), flush: true);
    await tmpFile.rename(finalFile.path);
  }

  Future<void> delete(String id) async {
    final file = await _fileFor(id);
    if (await file.exists()) await file.delete();
  }

  Future<void> deleteAll() async {
    final dir = await _directory();
    if (!await dir.exists()) return;
    for (final entity in dir.listSync()) {
      if (entity is File) await entity.delete();
    }
  }

  /// Liste tous les brouillons valides du répertoire, triés du plus
  /// récemment modifié au plus ancien. Un fichier individuellement corrompu
  /// est exclu de la liste plutôt que de faire échouer tout l'écran — il
  /// reste consultable (et son erreur visible) en l'ouvrant directement via
  /// [load].
  Future<List<DraftSummary>> listSummaries() async {
    final dir = await _directory();
    if (!await dir.exists()) return const [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    final contents = <String, String>{};
    final sizes = <String, int>{};
    for (final file in files) {
      contents[file.path] = await file.readAsString();
      sizes[file.path] = await file.length();
    }

    // Décodage déporté hors du fil principal (TP 7, partie C.5) : relire et
    // parser *toute* la liste des brouillons d'un coup est l'opération la
    // plus coûteuse de cet écran — contrairement au chargement d'un seul
    // brouillon (quelques dizaines d'octets, cf. `load`), qui ne le justifie
    // pas. Le volume croît avec le nombre de brouillons, pas leur taille
    // individuelle : c'est cette liste complète, pas un brouillon isolé, qui
    // mérite ce traitement.
    return compute(_parseSummaries, _ParseArgs(contents, sizes));
  }
}

class _ParseArgs {
  const _ParseArgs(this.contents, this.sizes);
  final Map<String, String> contents;
  final Map<String, int> sizes;
}

List<DraftSummary> _parseSummaries(_ParseArgs args) {
  final result = <DraftSummary>[];
  for (final entry in args.contents.entries) {
    final content = entry.value;
    if (content.trim().isEmpty) continue;
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      final draft = DraftRecord.fromJson(json);
      result.add(DraftSummary(
        id: draft.id,
        title: draft.title,
        lastModified: draft.lastModified,
        sizeBytes: args.sizes[entry.key] ?? 0,
      ));
    } catch (_) {
      // Fichier corrompu : exclu silencieusement de la liste (voir doc de
      // listSummaries).
    }
  }
  result.sort((a, b) => b.lastModified.compareTo(a.lastModified));
  return result;
}

/// Politique de purge (TP 7, partie C.4) : supprime, dans [directory], les
/// fichiers plus vieux que [maxAge] et/ou ceux qui font dépasser
/// [maxTotalBytes] en taille cumulée (du plus ancien au plus récent) — le
/// critère le plus contraignant déclenche. Pensée pour un répertoire de
/// type cache/temporaire (voir README, partie C.3) : les brouillons restent
/// des données que l'utilisateur gère explicitement (liste + suppression
/// individuelle), jamais purgées automatiquement.
Future<int> purgeDirectory(
  Directory directory, {
  Duration? maxAge,
  int? maxTotalBytes,
}) async {
  if (!await directory.exists()) return 0;
  var deleted = 0;

  if (maxAge != null) {
    final now = DateTime.now();
    for (final entity in directory.listSync().whereType<File>()) {
      if (now.difference(await entity.lastModified()) > maxAge) {
        await entity.delete();
        deleted++;
      }
    }
  }

  if (maxTotalBytes != null) {
    final remaining = directory.listSync().whereType<File>().toList()
      ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    var total = remaining.fold<int>(0, (sum, f) => sum + f.lengthSync());
    for (final file in remaining) {
      if (total <= maxTotalBytes) break;
      total -= file.lengthSync();
      await file.delete();
      deleted++;
    }
  }

  return deleted;
}
