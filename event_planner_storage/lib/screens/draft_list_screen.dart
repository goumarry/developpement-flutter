import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../storage/draft_repository.dart';
import '../utils/file_size_format.dart';
import 'draft_edit_screen.dart';

/// Liste des brouillons sur disque (TP 7, partie B).
class DraftListScreen extends StatefulWidget {
  const DraftListScreen({super.key, required this.repository});

  final DraftRepository repository;

  @override
  State<DraftListScreen> createState() => _DraftListScreenState();
}

class _DraftListScreenState extends State<DraftListScreen> {
  // Mémorisé une seule fois par intention (chargement initial, ou action
  // explicite de rechargement) — jamais recréé dans build() (voir TP 6).
  late Future<List<DraftSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.listSummaries();
  }

  void _reload() {
    setState(() => _future = widget.repository.listSummaries());
  }

  Future<void> _openDraft(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DraftEditScreen(id: id, repository: widget.repository),
      ),
    );
    _reload();
  }

  Future<void> _createDraft() async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _openDraft(id);
  }

  Future<void> _deleteOne(String id) async {
    await widget.repository.delete(id);
    _reload();
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer tous les brouillons ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.repository.deleteAll();
      _reload();
    }
  }

  /// Démonstration reproductible du cas limite "fichier corrompu" (TP 7,
  /// partie B) : écrit directement un JSON tronqué à la main (accolade
  /// fermante manquante), sans passer par [DraftRepository.save] — voir
  /// README pour la procédure manuelle équivalente.
  Future<void> _produceCorruptedDraftDemo() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory('${documents.path}/drafts');
    await dir.create(recursive: true);
    final file = File('${dir.path}/demo_corrompu.json');
    await file.writeAsString('{"id":"demo_corrompu","title":"Brouillon test"');
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brouillons'),
        actions: [
          IconButton(
            tooltip: 'Nouveau brouillon',
            icon: const Icon(Icons.add),
            onPressed: _createDraft,
          ),
          PopupMenuButton<VoidCallback>(
            tooltip: 'Actions',
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _deleteAll,
                child: const Text('Supprimer tous les brouillons'),
              ),
              PopupMenuItem(
                value: _produceCorruptedDraftDemo,
                child: const Text('Démo : produire un brouillon corrompu'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<DraftSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Impossible de lire les brouillons : ${snapshot.error}'),
            );
          }
          final drafts = snapshot.data ?? const [];
          if (drafts.isEmpty) {
            return const Center(child: Text('Aucun brouillon pour le moment.'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              itemCount: drafts.length,
              itemBuilder: (context, index) {
                final draft = drafts[index];
                return ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(
                    draft.title.trim().isEmpty ? '(sans titre)' : draft.title,
                  ),
                  subtitle: Text(
                    'Modifié le ${draft.lastModified.toLocal()} · '
                    '${formatFileSize(draft.sizeBytes)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Supprimer',
                    onPressed: () => _deleteOne(draft.id),
                  ),
                  onTap: () => _openDraft(draft.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
