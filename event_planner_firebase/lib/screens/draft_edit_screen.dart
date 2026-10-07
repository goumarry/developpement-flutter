import 'package:flutter/material.dart';

import '../models/draft_record.dart';
import '../storage/draft_lifecycle_observer.dart';
import '../storage/draft_repository.dart';

/// Édition d'un brouillon (TP 7, partie B).
///
/// Champs en saisie minimale (`TextField` simple, pas de `Form` ni de
/// validation — hors périmètre de ce TP). Le contenu est relu depuis le
/// disque à l'ouverture ; la sauvegarde est déclenchée explicitement (bouton)
/// ou automatiquement quand l'application passe en arrière-plan
/// ([DraftLifecycleObserver]).
class DraftEditScreen extends StatefulWidget {
  const DraftEditScreen({super.key, required this.id, required this.repository});

  final String id;
  final DraftRepository repository;

  @override
  State<DraftEditScreen> createState() => _DraftEditScreenState();
}

class _DraftEditScreenState extends State<DraftEditScreen> {
  late Future<DraftRecord> _future; // mémorisé une fois (voir TP 6/5)

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime? _date;
  bool _reminderEnabled = false;

  late final DraftLifecycleObserver _lifecycleObserver;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = DraftLifecycleObserver(onBackground: _saveSilently);
    _lifecycleObserver.attach();
    _future = _load();
  }

  Future<DraftRecord> _load() async {
    try {
      final draft = await widget.repository.load(widget.id);
      return draft ?? DraftRecord.empty(widget.id);
    } on DraftCorruptedException {
      rethrow; // affiché par la branche hasError du FutureBuilder
    }
  }

  void _applyToFields(DraftRecord draft) {
    _titleController.text = draft.title;
    _locationController.text = draft.location;
    _categoryController.text = draft.category;
    _date = draft.date;
    _reminderEnabled = draft.reminderEnabled;
    _loaded = true;
  }

  DraftRecord _currentDraft() => DraftRecord(
        id: widget.id,
        title: _titleController.text,
        location: _locationController.text,
        date: _date,
        category: _categoryController.text,
        lastModified: DateTime.now(),
        reminderEnabled: _reminderEnabled,
      );

  Future<void> _save() async {
    await widget.repository.save(_currentDraft());
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Brouillon enregistré.')));
  }

  /// Appelé par [DraftLifecycleObserver] sur `AppLifecycleState.paused` :
  /// pas de `SnackBar` ici (l'application n'est plus visible).
  void _saveSilently() {
    if (!_loaded) return; // rien à sauvegarder si le chargement initial a échoué
    widget.repository.save(_currentDraft());
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  void dispose() {
    _lifecycleObserver.detach();
    _titleController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brouillon'),
        actions: [
          IconButton(
            tooltip: 'Enregistrer',
            icon: const Icon(Icons.save_outlined),
            onPressed: _loaded ? _save : null,
          ),
        ],
      ),
      body: FutureBuilder<DraftRecord>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // DraftCorruptedException (ou toute autre erreur disque) :
            // dégradation propre, jamais un plantage ni une pile Dart brute.
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 12),
                    const Text(
                      'Brouillon illisible.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}'),
                  ],
                ),
              ),
            );
          }
          if (!_loaded) _applyToFields(snapshot.data!);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date (optionnelle)',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_date == null ? 'Non renseignée' : '${_date!.toLocal()}'.split(' ').first),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rappel activé'),
                value: _reminderEnabled,
                onChanged: (value) => setState(() => _reminderEnabled = value),
              ),
            ],
          );
        },
      ),
    );
  }
}
