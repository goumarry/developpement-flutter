import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/registration.dart';
import '../../state/auth_state.dart';
import '../../state/registration_cart_state.dart';
import '../routes.dart';
import '../utils/breakpoints.dart';
import '../utils/prompts.dart';
import '../widgets/state_views.dart';

/// Inscriptions de l'utilisateur : le panier (en cours, modifiable avant
/// confirmation finale) et les inscriptions déjà confirmées. Exige une
/// identité.
class MyRegistrationsScreen extends StatelessWidget {
  const MyRegistrationsScreen({super.key});

  Future<void> _confirm(BuildContext context) async {
    final result = await context.read<RegistrationCartState>().confirm();
    if (!context.mounted) return;
    showMessage(
      context,
      result.error ??
          (result.queuedOffline
              ? 'Inscriptions enregistrées hors connexion : elles seront '
                    'envoyées au retour du réseau.'
              : 'Inscriptions confirmées.'),
    );
  }

  Future<void> _cancel(BuildContext context, Registration registration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler cette inscription ?'),
        content: Text(
          '${registration.participantName} ne sera plus inscrit(e) à '
          '« ${registration.eventTitle} ».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Conserver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Annuler l’inscription'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await context.read<RegistrationCartState>().cancelConfirmed(
      registration,
    );
    if (!context.mounted) return;
    showMessage(context, result.error ?? 'Inscription annulée.');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final cart = context.watch<RegistrationCartState>();

    final Widget body;
    if (auth.status == AuthStatus.unknown) {
      body = const LoadingView(label: 'Vérification de la session…');
    } else if (!auth.isSignedIn) {
      body = SignInRequiredView(
        sessionExpired: auth.sessionExpired,
        reason: 'Vos inscriptions sont rattachées à votre compte.',
        onSignIn: () => Navigator.of(context).pushNamed(AppRoutes.auth),
      );
    } else if (cart.isEmpty &&
        cart.confirmed.isEmpty &&
        cart.confirmedError == null) {
      body = const EmptyView(
        icon: Icons.confirmation_number_outlined,
        title: 'Aucune inscription',
        message:
            'Ouvrez un événement du catalogue puis choisissez '
            '« S’inscrire » : il apparaîtra ici.',
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!cart.isEmpty) ...[
            _SectionTitle('En cours — à confirmer (${cart.lines.length})'),
            for (final line in cart.lines)
              _RegistrationTile(
                registration: line,
                actionIcon: Icons.remove_circle_outline,
                actionTooltip: 'Retirer du panier',
                onAction: () => cart.remove(line),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: cart.isConfirming ? null : () => _confirm(context),
              icon: cart.isConfirming
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(
                cart.isConfirming
                    ? 'Confirmation…'
                    : 'Confirmer ${cart.pendingSeats} place(s)',
              ),
            ),
            const SizedBox(height: 24),
          ],
          _SectionTitle('Confirmées (${cart.confirmed.length})'),
          if (cart.confirmedError != null)
            Text(
              cart.confirmedError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else if (cart.confirmed.isEmpty)
            const Text('Aucune inscription confirmée pour le moment.'),
          for (final registration in cart.confirmed)
            _RegistrationTile(
              registration: registration,
              actionIcon: Icons.delete_outline,
              actionTooltip: 'Annuler cette inscription',
              onAction: () => _cancel(context, registration),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mes inscriptions')),
      body: Center(
        child: ConstrainedBox(
          // Sur tablette, la liste reste une colonne lisible et centrée.
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.readableWidth,
          ),
          child: body,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _RegistrationTile extends StatelessWidget {
  const _RegistrationTile({
    required this.registration,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onAction,
  });

  final Registration registration;
  final IconData actionIcon;
  final String actionTooltip;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          registration.eventTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${registration.participantName} · ${registration.participantEmail}\n'
          '${registration.seats} place(s)',
        ),
        isThreeLine: true,
        // IconButton : zone tactile de 48 dp et infobulle lue par les
        // lecteurs d'écran.
        trailing: IconButton(
          icon: Icon(actionIcon),
          tooltip: actionTooltip,
          onPressed: onAction,
        ),
      ),
    );
  }
}
