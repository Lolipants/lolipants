import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';

/// Transparent floral overlay (`assets/images/lolipants_bg.png`) on [AppColors.ink].
///
/// Also applied globally in `app.dart` so every route shares the same
/// background. Per-screen copies are optional (e.g. when a route uses its own
/// [Stack] without inheriting the app builder).
class ArabesqueBackground extends StatelessWidget {
  /// Default opacity for the app-wide floral wallpaper.
  static const double defaultOpacity = 0.32;

  /// Creates the lace-style background.
  const ArabesqueBackground({
    this.opacity = defaultOpacity,
    super.key,
  });

  /// Overall alpha for the pattern layer (0.2–0.45 keeps UI readable).
  final double opacity;

  static const String _asset = 'assets/images/lolipants_bg.png';

  @override
  Widget build(BuildContext context) {
    final a = opacity.clamp(0.0, 1.0);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.ink),
          Opacity(
            opacity: a,
            child: Image.asset(
              _asset,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
