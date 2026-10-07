import 'package:flutter/material.dart';

/// En-tête "hero" : image de fond + voile dégradé + titre + avatar qui
/// déborde volontairement sous le cadre de l'image. Repris du TP 2/3.
///
/// Le [Stack] a `clipBehavior: Clip.none` pour que l'avatar reste visible
/// au-delà des 220px de l'image (pas rogné). La [SizedBox] englobante réserve
/// l'espace du débordement (`_avatarOverflow`) pour ne pas chevaucher le
/// contenu suivant dans la Column parente.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.title,
    required this.tagline,
    required this.backgroundImageUrl,
    required this.avatarImageUrl,
  });

  final String title;
  final String tagline;
  final String backgroundImageUrl;
  final String avatarImageUrl;

  static const double imageHeight = 220;
  static const double _avatarOverflow = 24;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: imageHeight + _avatarOverflow,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: imageHeight,
            child: Image.network(
              backgroundImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.black87),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: imageHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 100,
            bottom: _avatarOverflow + 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Positioned(
            top: imageHeight - 40,
            right: 20,
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 29,
                backgroundColor: Colors.black12,
                backgroundImage: NetworkImage(avatarImageUrl),
                onBackgroundImageError: (exception, stackTrace) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
