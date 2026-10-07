import 'package:flutter/material.dart';

import '../storage/preferences_store.dart';

/// Écran de réglages (TP 7, partie A) : un sélecteur par préférence,
/// appelant uniquement les setters de [PreferencesStore] — jamais
/// `shared_preferences` directement. État strictement local à cet écran :
/// les valeurs sont lues une fois dans `initState` (accesseurs synchrones,
/// [PreferencesStore.init] a déjà été attendue dans `main()`), puis
/// resynchronisées après chaque modification.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.prefsStore});

  final PreferencesStore prefsStore;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

const _knownScreens = ['home', 'settings', 'drafts'];

class _SettingsScreenState extends State<SettingsScreen> {
  late AppThemeMode _themeMode;
  late EventSortOrder _defaultSort;
  late DisplayDensity _displayDensity;
  late String _lastScreen;

  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _themeMode = widget.prefsStore.themeMode;
    _defaultSort = widget.prefsStore.defaultSort;
    _categoryController.text = widget.prefsStore.defaultCategoryFilter;
    _displayDensity = widget.prefsStore.displayDensity;
    _lastScreen = widget.prefsStore.lastScreen;
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionLabel('Thème'),
          SegmentedButton<AppThemeMode>(
            segments: const [
              ButtonSegment(value: AppThemeMode.light, label: Text('Clair')),
              ButtonSegment(value: AppThemeMode.dark, label: Text('Sombre')),
            ],
            selected: {_themeMode},
            onSelectionChanged: (selection) async {
              final mode = selection.first;
              await widget.prefsStore.setThemeMode(mode);
              setState(() => _themeMode = widget.prefsStore.themeMode);
            },
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Tri par défaut des événements'),
          SegmentedButton<EventSortOrder>(
            segments: const [
              ButtonSegment(value: EventSortOrder.date, label: Text('Date')),
              ButtonSegment(value: EventSortOrder.title, label: Text('Titre')),
              ButtonSegment(
                  value: EventSortOrder.popularity, label: Text('Popularité')),
            ],
            selected: {_defaultSort},
            onSelectionChanged: (selection) async {
              final order = selection.first;
              await widget.prefsStore.setDefaultSort(order);
              setState(() => _defaultSort = widget.prefsStore.defaultSort);
            },
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Catégorie filtrée par défaut'),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Vide = aucun filtre',
            ),
            onSubmitted: (value) async {
              await widget.prefsStore.setDefaultCategoryFilter(value);
            },
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Densité d\'affichage'),
          SegmentedButton<DisplayDensity>(
            segments: const [
              ButtonSegment(
                  value: DisplayDensity.comfortable, label: Text('Confortable')),
              ButtonSegment(
                  value: DisplayDensity.compact, label: Text('Compacte')),
            ],
            selected: {_displayDensity},
            onSelectionChanged: (selection) async {
              final density = selection.first;
              await widget.prefsStore.setDisplayDensity(density);
              setState(
                  () => _displayDensity = widget.prefsStore.displayDensity);
            },
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Dernier écran visité'),
          DropdownButton<String>(
            value: _lastScreen,
            isExpanded: true,
            items: [
              for (final screen in _knownScreens)
                DropdownMenuItem(value: screen, child: Text(screen)),
            ],
            onChanged: (value) async {
              if (value == null) return;
              await widget.prefsStore.setLastScreen(value);
              setState(() => _lastScreen = widget.prefsStore.lastScreen);
            },
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
