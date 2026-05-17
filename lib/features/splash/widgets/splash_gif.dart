import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/features/splash/splash_assets.dart';

/// Splash GIF image (bytes preloaded in [SplashAssets.warm] when possible).
class SplashGif extends StatelessWidget {
  /// Creates the splash GIF at the given layout size.
  const SplashGif({
    super.key,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
  });

  /// Width in logical pixels.
  final double width;

  /// Height in logical pixels.
  final double height;

  /// How the GIF fills its slot.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image(
        image: SplashAssets.imageProvider,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => _SplashGifPlaceholder(
          width: width,
          height: height,
        ),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null || wasSynchronouslyLoaded) {
            return child;
          }
          return _SplashGifPlaceholder(width: width, height: height);
        },
      ),
    );
  }
}

class _SplashGifPlaceholder extends StatelessWidget {
  const _SplashGifPlaceholder({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.gold.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
