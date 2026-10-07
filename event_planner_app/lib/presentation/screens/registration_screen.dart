import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/event.dart';
import '../../state/auth_state.dart';
import '../../state/registration_cart_state.dart';
import '../utils/breakpoints.dart';
import '../utils/formatters.dart';
import '../widgets/registration_form.dart';

/// Inscription d'un participant à [event]. Renvoie `true` à l'écran appelant
/// si l'inscription a été ajoutée au panier.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.event});

  final Event event;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  /// Refus d'une règle métier (capacité, doublon), affiché dans l'écran.
  String? _refusal;

  void _submit(RegistrationRequest request) {
    final outcome = context.read<RegistrationCartState>().add(
      event: widget.event,
      participantName: request.name,
      participantEmail: request.email,
      seats: request.seats,
    );
    if (outcome.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _refusal = _messageFor(outcome, request));
  }

  String _messageFor(CartOutcome outcome, RegistrationRequest request) {
    switch (outcome) {
      case CartOutcome.rejectedDuplicate:
        return '${request.email} est déjà inscrit(e) à cet événement. '
            'Utilisez une autre adresse, ou modifiez l’inscription existante '
            'depuis l’onglet « Inscriptions ».';
      case CartOutcome.rejectedFull:
        return 'Cet événement vient d’atteindre sa capacité : '
            'il n’est plus possible de s’y inscrire.';
      case CartOutcome.rejectedNotEnoughSeats:
        return 'Il ne reste pas assez de places pour ${request.seats} '
            'personne(s). Réduisez le nombre de places.';
      case CartOutcome.rejectedInvalidSeats:
        return 'Le nombre de places doit être d’au moins 1.';
      case CartOutcome.added:
      case CartOutcome.removed:
      case CartOutcome.rejectedNotFound:
        return 'L’inscription n’a pas pu être ajoutée.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = widget.event;
    final remaining = context.select<RegistrationCartState, int>(
      (cart) => cart.remainingSeats(event),
    );
    final user = context.read<AuthState>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Breakpoints.readableWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(event.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    dateRangeLabel(event.start, event.end),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  // Animation implicite : le message de refus se déplie.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    alignment: Alignment.topCenter,
                    child: _refusal == null
                        ? const SizedBox(width: double.infinity)
                        : _RefusalMessage(message: _refusal!),
                  ),
                  RegistrationForm(
                    remainingSeats: remaining,
                    initialEmail: user?.email ?? '',
                    initialName: user?.displayName ?? '',
                    onSubmit: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RefusalMessage extends StatelessWidget {
  const _RefusalMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(Icons.block, color: scheme.onErrorContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
