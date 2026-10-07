import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/organizer_event.dart';
import '../services/events_service.dart';
import '../utils/firestore_error_translator.dart';
import 'diagnostics_screen.dart';
import 'profile_screen.dart';

/// Espace organisateur (TP 8, partie C) : liste temps réel des événements de
/// l'utilisateur connecté. Atteignable uniquement via `AuthGate`.
class OrganizerHomeScreen extends StatefulWidget {
  const OrganizerHomeScreen({super.key});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  final EventsService _service = EventsService();
  late final AppUser _user;
  // Créé une fois : un `StreamBuilder` ne doit pas se réabonner à chaque
  // `build`. Aucun `StreamSubscription` manuel dans cet écran — le
  // StreamBuilder gère lui-même l'abonnement et l'annule à la destruction.
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    // Garanti non nul : cet écran n'existe que sous la branche « connecté »
    // de AuthGate.
    _user = AppUser.fromFirebase(FirebaseAuth.instance.currentUser!);
    _stream = _service.watchOwnEvents(_user.uid);
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(translateFirestoreError(error))),
    );
  }

  Future<void> _addEvent() async {
    final draft = await showDialog<_EventDraft>(
      context: context,
      builder: (_) => const _EventDialog(),
    );
    if (draft == null) return;
    // Volontairement pas d'`await` : hors ligne, `add` ne se résout qu'au
    // retour du réseau. L'événement apparaît tout de suite via le flux
    // (cache local, icône « en attente ») ; une erreur serveur (ex.
    // permission-denied) arrive plus tard et est traitée ici.
    _service
        .add(
          uid: _user.uid,
          title: draft.title,
          location: draft.location,
          date: draft.date,
        )
        .catchError(_showError);
  }

  Future<void> _rename(OrganizerEvent event) async {
    final controller = TextEditingController(text: event.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Renommer l'événement"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty) return;
    _service.rename(event.id, title).catchError(_showError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace organisateur'),
        actions: [
          IconButton(
            tooltip: 'Diagnostic règles / index',
            icon: const Icon(Icons.rule),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DiagnosticsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Mon profil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEvent,
        icon: const Icon(Icons.add),
        label: const Text('Événement'),
      ),
      body: Column(
        children: [
          const VerificationBanner(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorView(
                    error: snapshot.error!,
                    onRetry: () => setState(
                      () => _stream = _service.watchOwnEvents(_user.uid),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!;
                final events = EventsService.toSortedEvents(data);
                return Column(
                  children: [
                    _SourceBar(
                      fromCache: data.metadata.isFromCache,
                      pending: data.metadata.hasPendingWrites,
                    ),
                    Expanded(
                      child: events.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  "Aucun événement pour l'instant. Appuyez sur "
                                  '« Événement » pour en créer un.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: events.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, i) => _EventTile(
                                event: events[i],
                                onTap: () => _rename(events[i]),
                                onDelete: () => _service
                                    .delete(events[i].id)
                                    .catchError(_showError),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau « adresse non vérifiée » : observe `userChanges()` pour se mettre à
/// jour dès que `emailVerified` change (après `reload()`), sans bloquer
/// l'accès.
class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null || user.emailVerified) return const SizedBox.shrink();
        return MaterialBanner(
          leading: const Icon(Icons.mark_email_unread_outlined),
          content: Text(
            'Adresse non vérifiée (${user.email}). Ouvrez le lien reçu par '
            'courriel, puis actualisez.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await user.sendEmailVerification();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Courriel de vérification renvoyé.')),
                  );
                } on FirebaseAuthException {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Envoi impossible pour le moment : réessayez plus tard.'),
                    ),
                  );
                }
              },
              child: const Text('Renvoyer'),
            ),
            TextButton(
              // `reload()` relit le profil côté serveur ; `userChanges()`
              // émet alors l'utilisateur mis à jour.
              onPressed: () => user.reload(),
              child: const Text('Actualiser'),
            ),
          ],
        );
      },
    );
  }
}

/// Provenance de l'ensemble du snapshot (cache local vs serveur).
class _SourceBar extends StatelessWidget {
  const _SourceBar({required this.fromCache, required this.pending});

  final bool fromCache;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final String text = pending
        ? 'Modifications locales en attente de confirmation serveur'
        : fromCache
            ? 'Données du cache local (serveur non confirmé)'
            : 'Données confirmées par le serveur';
    final IconData icon = pending
        ? Icons.cloud_upload_outlined
        : fromCache
            ? Icons.cloud_off_outlined
            : Icons.cloud_done_outlined;
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.onTap,
    required this.onDelete,
  });

  final OrganizerEvent event;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String tip;
    if (event.hasPendingWrites) {
      icon = Icons.cloud_upload_outlined;
      tip = 'Écriture locale, pas encore confirmée par le serveur';
    } else if (event.isFromCache) {
      icon = Icons.cloud_off_outlined;
      tip = 'Donnée issue du cache local';
    } else {
      icon = Icons.cloud_done_outlined;
      tip = 'Confirmé par le serveur';
    }
    final parts = <String>[
      if (event.location.isNotEmpty) event.location,
      if (event.date != null) DateFormat.yMMMEd('fr_FR').format(event.date!),
    ];
    return ListTile(
      title: Text(event.title),
      subtitle: parts.isEmpty ? null : Text(parts.join(' · ')),
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(message: tip, child: Icon(icon, size: 20)),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermissionDenied(error) ? Icons.lock_outline : Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(translateFirestoreError(error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _EventDraft {
  const _EventDraft(this.title, this.location, this.date);
  final String title;
  final String location;
  final DateTime date;
}

class _EventDialog extends StatefulWidget {
  const _EventDialog();

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvel événement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          TextField(
            controller: _location,
            decoration: const InputDecoration(labelText: 'Lieu'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(DateFormat.yMMMEd('fr_FR').format(_date)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final title = _title.text.trim();
            if (title.isEmpty) return;
            Navigator.pop(
              context,
              _EventDraft(title, _location.text.trim(), _date),
            );
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
