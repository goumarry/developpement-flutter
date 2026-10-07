import 'package:flutter/material.dart';

import '../utils/breakpoints.dart';

/// Les quatre états transverses de l'application, chacun avec son rendu
/// propre — utilisés par **tous** les écrans, pour qu'un même état se
/// reconnaisse partout :
///
/// * [LoadingView] — chargement en cours ;
/// * [EmptyView] — absence légitime de données ;
/// * [ErrorView] — échec (réseau, serveur, règle refusée), avec reprise ;
/// * [SignInRequiredView] — identité requise : non connecté ou session expirée.

/// Chargement en cours.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Chargement…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            ExcludeSemantics(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

/// Absence de données : ce n'est pas une erreur (ton neutre, pas de rouge).
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StateLayout(
      icon: icon,
      iconColor: scheme.onSurfaceVariant,
      title: title,
      message: message,
      action: actionLabel == null
          ? null
          : OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
    );
  }
}

/// Échec : message rédigé pour l'utilisateur (jamais une trace technique) et
/// action de reprise.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StateLayout(
      icon: Icons.error_outline,
      iconColor: scheme.error,
      title: 'Une erreur est survenue',
      titleColor: scheme.error,
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
    );
  }
}

/// Écran qui exige une identité, affiché à un utilisateur non connecté — ou
/// dont la session a pris fin sans qu'il l'ait demandé ([sessionExpired]).
/// Propose toujours l'authentification, jamais un échec muet.
class SignInRequiredView extends StatelessWidget {
  const SignInRequiredView({
    super.key,
    required this.reason,
    required this.onSignIn,
    this.sessionExpired = false,
  });

  /// Ce que la connexion permettra de faire sur cet écran.
  final String reason;
  final VoidCallback onSignIn;
  final bool sessionExpired;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StateLayout(
      icon: sessionExpired ? Icons.lock_clock_outlined : Icons.lock_outline,
      iconColor: scheme.primary,
      title: sessionExpired ? 'Session expirée' : 'Connexion requise',
      message: sessionExpired
          ? 'Votre session a pris fin. Reconnectez-vous pour continuer. $reason'
          : reason,
      action: FilledButton.icon(
        onPressed: onSignIn,
        icon: const Icon(Icons.login),
        label: Text(sessionExpired ? 'Se reconnecter' : 'Se connecter'),
      ),
    );
  }
}

/// Gabarit commun : icône, titre, message, action. Défilable et centré, donc
/// sans débordement sur un petit écran ou avec une grande taille de police,
/// et compatible avec un `RefreshIndicator` parent.
class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Breakpoints.readableWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Icon(icon, size: 56, color: iconColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(color: titleColor),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                    if (action != null) ...[
                      const SizedBox(height: 20),
                      action!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
