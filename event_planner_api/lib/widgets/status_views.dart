import 'package:flutter/material.dart';

import '../api/exceptions.dart';

/// Chargement plein écran — réservé au *premier* chargement d'une liste
/// (page 0) ou à l'écran de détail. Distinct de [ListFooterStatus].
class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Branche d'erreur du `FutureBuilder` : message en français, jamais une
/// trace d'exception Dart brute, avec action de nouvelle tentative.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  /// Traduit n'importe quelle erreur de couche réseau en message affichable.
  /// Les quatre types d'[ApiException] sont distingués par leur propre
  /// message (défini dans `lib/api/exceptions.dart`) ; tout le reste (erreur
  /// non prévue) retombe sur un message générique, jamais sur `error.toString()`.
  static String messageFor(Object? error) {
    if (error is ApiException) return error.message;
    return 'Une erreur inattendue est survenue, veuillez réessayer.';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off,
                size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// État vide — volontairement distinct d'[ErrorView] : une recherche sans
/// résultat renvoie un code 200 avec une liste vide, ce n'est pas un échec.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicateur de pied de liste pour le chargement de la page suivante —
/// discret, ne masque jamais les éléments déjà chargés. Affiche aussi
/// l'erreur d'une page suivante ratée, avec reprise, sans toucher à la liste.
class ListFooterStatus extends StatelessWidget {
  const ListFooterStatus({
    super.key,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
    this.reachedEnd = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool reachedEnd;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (reachedEnd) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Fin de la liste',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}
