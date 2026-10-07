import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/event.dart';
import '../../state/auth_state.dart';
import '../../state/organizer_events_state.dart';
import '../routes.dart';
import '../utils/prompts.dart';
import '../widgets/event_collection.dart';
import '../widgets/state_views.dart';

enum _EventAction { edit, delete }

/// Espace organisateur : les événements créés par le compte connecté, et
/// uniquement ceux-là. Exige une identité.
class OrganizerDashboardScreen extends StatelessWidget {
  const OrganizerDashboardScreen({super.key});

  /// Ouvre l'éditeur ([event] nul = création) et affiche le message qu'il
  /// renvoie en valeur de retour.
  Future<void> _openEditor(BuildContext context, {Event? event}) async {
    final signedIn = await ensureSignedIn(
      context,
      reason: 'Connectez-vous pour créer et gérer vos événements.',
    );
    if (!signedIn || !context.mounted) return;
    final message = await Navigator.of(context)
        .pushNamed<String>(AppRoutes.eventEditor, arguments: event);
    if (message != null && context.mounted) showMessage(context, message);
  }

  Future<void> _delete(BuildContext context, Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cet événement ?'),
        content: Text('« ${event.title} » sera supprimé définitivement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await context.read<OrganizerEventsState>().delete(event.id);
    if (!context.mounted) return;
    showMessage(
      context,
      result.error ??
          (result.queuedOffline
              ? 'Suppression enregistrée hors connexion.'
              : 'Événement supprimé.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final organizer = context.watch<OrganizerEventsState>();

    final Widget body;
    if (auth.status == AuthStatus.unknown) {
      body = const LoadingView(label: 'Vérification de la session…');
    } else if (!auth.isSignedIn) {
      body = SignInRequiredView(
        sessionExpired: auth.sessionExpired,
        reason:
            'L’espace organisateur permet de créer, modifier et supprimer '
            'vos propres événements.',
        onSignIn: () => Navigator.of(context).pushNamed(AppRoutes.auth),
      );
    } else {
      switch (organizer.status) {
        case OrganizerStatus.signedOut:
        case OrganizerStatus.loading:
          body = const LoadingView(label: 'Chargement de vos événements…');
        case OrganizerStatus.error:
          body = ErrorView(
            message:
                organizer.errorMessage ?? 'Vos événements sont indisponibles.',
            onRetry: organizer.retry,
          );
        case OrganizerStatus.loaded:
          body = organizer.events.isEmpty
              ? EmptyView(
                  icon: Icons.edit_calendar_outlined,
                  title: 'Aucun événement créé',
                  message:
                      'Créez votre premier événement : vous seul pourrez '
                      'le voir et le modifier.',
                  actionLabel: 'Créer un événement',
                  onAction: () => _openEditor(context),
                )
              : CustomScrollView(
                  slivers: [
                    EventCollectionSliver(
                      events: organizer.events,
                      onTap: (event) => Navigator.of(context).pushNamed(
                        AppRoutes.eventDetail,
                        arguments: EventDetailArgs.of(event),
                      ),
                      trailingBuilder: (event) => PopupMenuButton<_EventAction>(
                        tooltip: 'Actions pour ${event.title}',
                        onSelected: (action) => switch (action) {
                          _EventAction.edit => _openEditor(
                            context,
                            event: event,
                          ),
                          _EventAction.delete => _delete(context, event),
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: _EventAction.edit,
                            child: Text('Modifier'),
                          ),
                          PopupMenuItem(
                            value: _EventAction.delete,
                            child: Text('Supprimer'),
                          ),
                        ],
                      ),
                    ),
                    // Laisse la dernière carte visible au-dessus du bouton
                    // flottant.
                    const SliverToBoxAdapter(child: SizedBox(height: 88)),
                  ],
                );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace organisateur'),
        bottom: auth.isSignedIn
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'Connecté : ${auth.user!.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: body,
      floatingActionButton: auth.isSignedIn
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('Nouvel événement'),
            )
          : null,
    );
  }
}
