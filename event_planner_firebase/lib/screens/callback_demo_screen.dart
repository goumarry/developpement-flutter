import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// PARTIE A.1 du TP 4 — version « callback » conservée volontairement.
///
/// Ce n'est pas l'application réelle : c'est le montage à trois niveaux de
/// widgets qui remonte un compteur par callbacks + `setState`, gardé pour que
/// la mesure de recompositions du README soit **reproductible**. Les widgets de
/// `lib/widgets/` (EventSection, EventTile, CartBadge) sont la version A.3 des
/// mêmes rôles, refactorée avec Provider.
///
/// Chaque widget de ce fichier incrémente un compteur statique `builds` et
/// appelle `debugPrint` : appuyez 5 fois sur « + 1 » et lisez les compteurs
/// (panneau en bas de l'écran, ou console `flutter run`).
class CallbackDemoScreen extends StatefulWidget {
  const CallbackDemoScreen({super.key});

  @override
  State<CallbackDemoScreen> createState() => _CallbackDemoScreenState();
}

class _CallbackDemoScreenState extends State<CallbackDemoScreen> {
  int _registrationCount = 0;

  void _increment() => setState(() => _registrationCount++);

  void _reset() {
    setState(() {
      _registrationCount = 0;
      _CallbackTile.builds = 0;
      _CallbackSection.builds = 0;
      _CallbackBadge.builds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Démo recompositions — callbacks'),
        actions: [
          _CallbackBadge(count: _registrationCount),
          IconButton(
            tooltip: 'Remettre les compteurs à zéro',
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Le compteur est détenu par l\'écran (niveau 1) et redescendu en '
              'paramètre à EventSection (niveau 2) puis EventTile (niveau 3), '
              'ainsi qu\'au badge de l\'AppBar. Un seul « + 1 » reconstruit les '
              'trois.',
            ),
          ),
          _CallbackSection(
            count: _registrationCount,
            onIncrement: _increment,
          ),
          const SizedBox(height: 16),
          _CountsPanel(tick: _registrationCount),
        ],
      ),
    );
  }
}

/// Niveau 2 — ne se sert pas du compteur, se contente de le faire transiter.
class _CallbackSection extends StatelessWidget {
  const _CallbackSection({required this.count, required this.onIncrement});

  final int count;
  final VoidCallback onIncrement;

  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    if (kDebugMode) debugPrint('BUILD _CallbackSection (#$builds)');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Section (niveau 2)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _CallbackTile(count: count, onIncrement: onIncrement),
        ],
      ),
    );
  }
}

/// Niveau 3 — affiche le compteur et porte le bouton.
class _CallbackTile extends StatelessWidget {
  const _CallbackTile({required this.count, required this.onIncrement});

  final int count;
  final VoidCallback onIncrement;

  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    if (kDebugMode) debugPrint('BUILD _CallbackTile (#$builds)');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text('Inscriptions : $count',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            FilledButton(onPressed: onIncrement, child: const Text('+ 1')),
          ],
        ),
      ),
    );
  }
}

/// Badge d'AppBar alimenté par paramètre depuis l'écran.
class _CallbackBadge extends StatelessWidget {
  const _CallbackBadge({required this.count});

  final int count;

  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    if (kDebugMode) debugPrint('BUILD _CallbackBadge (#$builds)');
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Chip(label: Text('$count')),
      ),
    );
  }
}

/// Panneau de lecture des compteurs. Widget **frère** des widgets mesurés : ses
/// propres reconstructions n'influencent pas leurs compteurs. À chaque
/// changement de [tick], il se resynchronise une fois **après la frame**.
class _CountsPanel extends StatefulWidget {
  const _CountsPanel({required this.tick});

  final int tick;

  @override
  State<_CountsPanel> createState() => _CountsPanelState();
}

class _CountsPanelState extends State<_CountsPanel> {
  @override
  void didUpdateWidget(_CountsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tick != widget.tick) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tile = _CallbackTile.builds;
    final section = _CallbackSection.builds;
    final badge = _CallbackBadge.builds;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appels à build()', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('_CallbackTile     : $tile'),
            Text('_CallbackSection  : $section'),
            Text('_CallbackBadge    : $badge'),
          ],
        ),
      ),
    );
  }
}
