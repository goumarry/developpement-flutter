import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/events_service.dart';
import '../utils/firestore_error_translator.dart';

/// Écran de diagnostic (TP 8, partie C) : provoque volontairement, depuis
/// l'application, les trois échecs à documenter — refus des règles (lecture
/// non filtrée, écriture sur l'événement d'autrui) et index manquant. Chaque
/// résultat affiche le message utilisateur ET le code Firestore brut (outil
/// de diagnostic de l'étudiant, pas un écran destiné aux organisateurs).
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final EventsService _service = EventsService();
  final _otherEventId = TextEditingController();
  final List<String> _log = [];

  @override
  void dispose() {
    _otherEventId.dispose();
    super.dispose();
  }

  Future<void> _run(String label, Future<Object?> Function() action) async {
    String line;
    try {
      final result = await action();
      line = '✔ $label : autorisé ($result)';
    } catch (e) {
      final code = e is FirebaseException ? e.code : e.runtimeType.toString();
      final detail = e is FirebaseException ? (e.message ?? '') : '';
      line = '✘ $label\n   code = $code\n   ${translateFirestoreError(e)}'
          '${code == 'failed-precondition' ? '\n   message Firestore : $detail' : ''}';
    }
    if (mounted) setState(() => _log.insert(0, line));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostic règles / index')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton(
            onPressed: () => _run(
              'Lire toute la collection events (sans filtre ownerId)',
              () async => (await _service.tryReadAllEvents()).size,
            ),
            child: const Text('Lire TOUS les événements'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _otherEventId,
            decoration: const InputDecoration(
              labelText: "ID d'un événement d'un autre organisateur",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              final id = _otherEventId.text.trim();
              if (id.isEmpty) return;
              _run(
                "Modifier l'événement $id",
                () async {
                  await _service.tryUpdateAnyEvent(id);
                  return 'écriture acceptée';
                },
              );
            },
            child: const Text("Modifier l'événement d'autrui"),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _run(
              'where(ownerId) + orderBy(date) sans index composite',
              () async => (await _service.queryNeedingCompositeIndex(uid)).size,
            ),
            child: const Text('Requête sans index composite'),
          ),
          const Divider(height: 32),
          if (_log.isEmpty) const Text('Aucun test lancé.'),
          for (final line in _log)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SelectableText(line),
            ),
        ],
      ),
    );
  }
}
