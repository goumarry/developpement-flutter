import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/event_repository.dart';
import '../models/event.dart';
import '../routes/app_routes.dart';
import '../state/display_preferences.dart';
import '../widgets/cart_badge.dart';
import '../widgets/event_section.dart';
import '../widgets/event_tile.dart';

/// Écran « Événements » du TP 4 : liste pilotée par `DisplayPreferences`
/// (tri / filtre / densité, via Provider), à ne pas confondre avec le mur
/// décoratif du TP 2/3 (`EventWallScreen`, onglet « Accueil »).
///
/// **StatelessWidget** : `watch` uniquement `DisplayPreferences` ; il
/// n'observe pas `RegistrationCart`, donc une mutation du panier ne le
/// reconstruit pas — seuls le [CartBadge] et la tuile concernée se
/// reconstruisent.
class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  static const _repository = EventRepository();

  /// Compteur de recompositions (mesure Partie A, TP 4). Voir README.
  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    if (kDebugMode) debugPrint('BUILD EventListScreen (#$builds)');

    final prefs = context.watch<DisplayPreferences>();
    final List<Event> events = prefs.applyTo(_repository.allEvents());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements (Provider)'),
        actions: [
          const CartBadge(),
          PopupMenuButton<String>(
            onSelected: (_) =>
                Navigator.of(context).pushNamed(AppRoutes.callbackDemo),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'demo',
                child: Text('Démo recompositions (Partie A)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _PreferencesBar(categories: _repository.categories()),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                EventSection(
                  title: 'Prochains événements',
                  subtitle: '${events.length} affiché(s)',
                  children: [
                    for (final event in events) EventTile(event: event),
                    if (events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('Aucun événement pour ce filtre.'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre de préférences d'affichage. Lit et mute `DisplayPreferences`
/// exclusivement via ses méthodes publiques (`context.read`).
class _PreferencesBar extends StatelessWidget {
  const _PreferencesBar({required this.categories});

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<DisplayPreferences>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: _Dropdown<EventSort>(
                  icon: Icons.sort,
                  value: prefs.sort,
                  values: EventSort.values,
                  labelOf: (s) => s.label,
                  onChanged: (s) =>
                      context.read<DisplayPreferences>().setSort(s),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _Dropdown<EventDensity>(
                  icon: Icons.density_medium,
                  value: prefs.density,
                  values: EventDensity.values,
                  labelOf: (d) => d.label,
                  onChanged: (d) =>
                      context.read<DisplayPreferences>().setDensity(d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final category in categories)
                FilterChip(
                  label: Text(category),
                  selected: prefs.category == category,
                  onSelected: (_) => context
                      .read<DisplayPreferences>()
                      .toggleCategory(category),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.icon,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final IconData icon;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: DropdownButton<T>(
              value: value,
              underline: const SizedBox.shrink(),
              isDense: true,
              isExpanded: true,
              items: [
                for (final v in values)
                  DropdownMenuItem(value: v, child: Text(labelOf(v))),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
