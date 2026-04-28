import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';

/// Full-screen blocking overlay with a gold progress indicator.
///
/// Place as the last child of a [Stack] so it covers prior siblings.
class LoadingOverlay extends StatelessWidget {
  /// When false, renders an empty [SizedBox.shrink].
  const LoadingOverlay({
    required this.visible,
    super.key,
  });

  /// Toggles visibility of the overlay.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Semantics(
        label: 'Loading',
        liveRegion: true,
        child: AbsorbPointer(
          child: ColoredBox(
            color: AppColors.ink.withValues(alpha: 0.88),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
