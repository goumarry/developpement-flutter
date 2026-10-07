import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Bandeau du mode dégradé : signale que les données affichées viennent de la
/// copie locale et **ne sont pas fraîches**, avec leur date.
///
/// [staleSince] nul = données fraîches : le bandeau se replie. L'apparition
/// et la disparition sont animées implicitement (`AnimatedSize` +
/// `AnimatedSwitcher`). `liveRegion` : un lecteur d'écran annonce le bandeau
/// dès qu'il apparaît.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.staleSince, this.onRetry});

  final DateTime? staleSince;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final since = staleSince;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: since == null
            ? const SizedBox(width: double.infinity)
            : _BannerContent(since: since, onRetry: onRetry),
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({required this.since, this.onRetry});

  final DateTime since;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppStatusColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        color: colors.warningContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.cloud_off_outlined,
                  color: colors.onWarningContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Catalogue non actualisé — copie locale du '
                  '${dateLabel(since)}, peut-être plus à jour.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onWarningContainer,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onWarningContainer,
                  ),
                  child: const Text('Réessayer'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
