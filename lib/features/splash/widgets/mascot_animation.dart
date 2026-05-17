import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/features/splash/widgets/splash_gif.dart';

/// Splash mascot slot: animated GIF inside the branded rounded frame.
class MascotAnimation extends StatelessWidget {
  /// Creates the mascot animation at its default splash size.
  const MascotAnimation({
    super.key,
    this.width = 230,
    this.height = 162,
  });

  /// Target width in logical pixels.
  final double width;

  /// Target height in logical pixels.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFCD800),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: SplashGif(width: width, height: height, fit: BoxFit.contain),
    );
  }
}
