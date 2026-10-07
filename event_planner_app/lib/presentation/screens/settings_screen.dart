import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/app_preferences.dart';
import '../../domain/models/network_demo_mode.dart';
import '../../state/auth_state.dart';
import '../../state/catalog_state.dart';
import '../../state/network_demo_state.dart';
import '../../state/preferences_state.dart';
import '../routes.dart';
import '../utils/breakpoints.dart';
import '../utils/prompts.dart';

/// Réglages : préférences persistantes (thème, tri par défaut), compte et
/// outils de démonstration réseau.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Applique une préférence puis prévient si elle n'a pas pu être écrite
  /// sur le disque.
  Future<void> _apply(
    BuildContext context,
    Future<bool> Function() save,
  ) async {
    final saved = await save();
    if (saved || !context.mounted) return;
    showMessage(
      context,
      'Préférence appliquée, mais non enregistrée : elle sera perdue au '
      'prochain lancement.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesState>();
    final auth = context.watch<AuthState>();
    final demo = context.watch<NetworkDemoState>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.readableWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              const _SectionHeader('Apparence'),
              for (final theme in ThemePreference.values)
                _ChoiceTile(
                  label: 'Thème ${theme.label.toLowerCase()}',
                  selected: preferences.theme == theme,
                  onTap: () =>
                      _apply(context, () => preferences.setTheme(theme)),
                ),
              const Divider(),
              const _SectionHeader('Tri par défaut du catalogue'),
              for (final sort in EventSort.values)
                _ChoiceTile(
                  label: sort.label,
                  selected: preferences.defaultSort == sort,
                  onTap: () {
                    // Le choix devient le tri au prochain lancement, et
                    // s'applique aussi tout de suite au catalogue ouvert.
                    context.read<CatalogState>().setSort(sort);
                    _apply(context, () => preferences.setDefaultSort(sort));
                  },
                ),
              const Divider(),
              const _SectionHeader('Compte'),
              if (user == null)
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Se connecter ou créer un compte'),
                  subtitle: const Text(
                    'Nécessaire pour s’inscrire et organiser des événements.',
                  ),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.auth),
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(user.label),
                  subtitle: const Text('Connecté'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Se déconnecter'),
                  onTap: () async {
                    final result = await auth.signOut();
                    if (context.mounted) {
                      showMessage(
                        context,
                        result.error ?? 'Vous êtes déconnecté.',
                      );
                    }
                  },
                ),
              ],
              const Divider(),
              const _SectionHeader('Démonstration réseau'),
              for (final mode in NetworkDemoMode.values)
                _ChoiceTile(
                  label: mode.label,
                  description: mode.description,
                  selected: demo.mode == mode,
                  onTap: () {
                    demo.setMode(mode);
                    // Relance le catalogue pour que l'effet soit visible
                    // sans autre manipulation.
                    context.read<CatalogState>().refresh();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Ligne de choix exclusif. Toute la ligne est cliquable (bien plus que les
/// 48 dp requis) ; l'état est porté par une coche **et** par la sémantique
/// `selected`, pas seulement par la couleur.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
  });

  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: description == null ? null : Text(description!),
      selected: selected,
      trailing: AnimatedOpacity(
        opacity: selected ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.check),
      ),
      onTap: onTap,
    );
  }
}
