import 'package:flutter/material.dart';

/// Brand watermark from `assets/images/lolipants_bg.png` at very low opacity.
///
/// Renders behind screen content; pointer events are ignored.
class ArabesqueBackground extends StatelessWidget {
  /// Creates the lace-style background.
  const ArabesqueBackground({
    this.opacity = 0.08,
    super.key,
  });

  /// Overall alpha for the image layer (keep low; 0.03–0.08 typical).
  final double opacity;

  static const String _asset = 'assets/images/lolipants_bg.png';

  @override
  Widget build(BuildContext context) {
    final a = opacity.clamp(0.0, 1.0);
    return IgnorePointer(
      child: Opacity(
        opacity: a,
        child: SizedBox.expand(
          child: Image.asset(
            _asset,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
