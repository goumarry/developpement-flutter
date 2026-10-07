import 'package:flutter/material.dart';

import '../storage/app_storage.dart';
import 'draft_list_screen.dart';
import 'settings_screen.dart';

/// Racine de l'onglet « Stockage » (TP 7) : point d'entrée vers les
/// réglages persistants et les brouillons sur disque.
class StorageHubScreen extends StatelessWidget {
  const StorageHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stockage local')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Réglages'),
              subtitle: const Text('TP 7, partie A — préférences persistantes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(prefsStore: prefsStore),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.drafts_outlined),
              title: const Text('Mes brouillons'),
              subtitle: const Text('TP 7, partie B — brouillons sur disque'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DraftListScreen(repository: draftRepository),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
