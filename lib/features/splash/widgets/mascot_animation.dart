import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';

/// Placeholder region for the Rive panda mascot (130×160).
class MascotAnimation extends StatelessWidget {
  /// Reserves layout space for the mascot asset.
  const MascotAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ember,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Icon(Icons.pets, color: AppColors.gold.withValues(alpha: 0.35)),
    );
  }
}
