import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/failures.dart';
import '../../domain/models/event.dart';
import '../../domain/rules/capacity_rule.dart';
import '../../state/catalog_state.dart';
import '../../state/registration_cart_state.dart';
import '../routes.dart';
import '../utils/breakpoints.dart';
import '../utils/formatters.dart';
import '../utils/prompts.dart';
import '../widgets/capacity_gauge.dart';
import '../widgets/event_image.dart';
import '../widgets/state_views.dart';

/// Détail d'un événement (catalogue ou organisateur) et point d'entrée de
/// l'inscription.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.args});

  final EventDetailArgs args;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? _event;
  String? _error;
  bool _refreshFailed = false;

  @override
  void initState() {
    super.initState();
    _event = widget.args.preview;
    // Un événement d'organisateur est déjà complet et tenu à jour par son
    // flux temps réel ; seul un événement du catalogue est rechargé.
    if (_event?.ownerId == null) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final event = await context.read<CatalogState>().fetchEvent(
        widget.args.eventId,
      );
      if (!mounted) return;
      setState(() {
        _event = event;
        _refreshFailed = false;
      });
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        // Avec un aperçu, l'échec du rafraîchissement n'efface rien : on le
        // signale seulement. Sans aperçu, c'est l'état d'erreur plein écran.
        if (_event == null) {
          _error = failure.message;
        } else {
          _refreshFailed = true;
        }
      });
    }
  }

  Future<void> _register(Event event) async {
    final signedIn = await ensureSignedIn(
      context,
      reason: 'Connectez-vous pour vous inscrire à « ${event.title} ».',
    );
    if (!signedIn || !mounted) return;
    final added = await Navigator.of(context)
        .pushNamed<bool>(AppRoutes.registration, arguments: event);
    if (added == true && mounted) {
      showMessage(
        context,
        'Inscription ajoutée. Confirmez-la dans l’onglet « Inscriptions ».',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    return Scaffold(
      appBar: AppBar(title: const Text('Événement')),
      body: SafeArea(
        child: event != null
            ? _EventDetailBody(
                event: event,
                refreshFailed: _refreshFailed,
                onRegister: () => _register(event),
              )
            : _error != null
            ? ErrorView(message: _error!, onRetry: _load)
            : const LoadingView(label: 'Chargement de l’événement…'),
      ),
    );
  }
}

class _EventDetailBody extends StatelessWidget {
  const _EventDetailBody({
    required this.event,
    required this.refreshFailed,
    required this.onRegister,
  });

  final Event event;
  final bool refreshFailed;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    // Places de l'utilisateur (panier + confirmées) : la jauge et le bouton
    // reflètent immédiatement une inscription ajoutée ou retirée.
    final held = context.select<RegistrationCartState, int>(
      (cart) => cart.heldSeats(event.id),
    );
    final taken = event.registered + held;
    final remaining = CapacityRule.remaining(
      capacity: event.capacity,
      taken: taken,
    );

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: EventImage(event: event),
      ),
    );
    final info = _EventInfo(
      event: event,
      taken: taken,
      remaining: remaining,
      held: held,
      refreshFailed: refreshFailed,
      onRegister: onRegister,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tablette : deux volets côte à côte. Téléphone : une colonne.
        if (constraints.maxWidth >= Breakpoints.tablet) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: image),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: info),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [image, const SizedBox(height: 16), info],
          ),
        );
      },
    );
  }
}

class _EventInfo extends StatelessWidget {
  const _EventInfo({
    required this.event,
    required this.taken,
    required this.remaining,
    required this.held,
    required this.refreshFailed,
    required this.onRegister,
  });

  final Event event;
  final int taken;
  final int remaining;
  final int held;
  final bool refreshFailed;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(event.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        _InfoLine(
          icon: Icons.schedule,
          text: dateRangeLabel(event.start, event.end),
        ),
        _InfoLine(
          icon: event.isOnline ? Icons.videocam_outlined : Icons.place_outlined,
          text: event.isOnline
              ? 'En ligne'
              : event.location.isEmpty
              ? 'Lieu à confirmer'
              : event.location,
        ),
        _InfoLine(
          icon: Icons.sell_outlined,
          text:
              '${event.category.isEmpty ? 'Divers' : event.category} · '
              '${priceLabel(event.price)}',
        ),
        if (event.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(event.description, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: 20),
        CapacityGauge(taken: taken, capacity: event.capacity),
        if (held > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'dont $held place(s) pour vos inscriptions',
              style: theme.textTheme.bodySmall,
            ),
          ),
        // Animation implicite : l'avertissement apparaît en fondu.
        AnimatedOpacity(
          opacity: refreshFailed ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: refreshFailed
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Hors connexion : ces informations n’ont pas pu être '
                    'actualisées.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          // Désactivé quand l'événement est complet : le libellé dit pourquoi.
          onPressed: remaining > 0 ? onRegister : null,
          icon: Icon(remaining > 0 ? Icons.how_to_reg : Icons.block),
          label: Text(
            remaining > 0
                ? 'S’inscrire ($remaining place(s) restante(s))'
                : 'Complet',
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
