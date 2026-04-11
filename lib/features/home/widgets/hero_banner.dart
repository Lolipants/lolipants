import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';

/// Home hero marketing card (Phase 2 layout).
class HeroBanner extends StatelessWidget {
  /// Creates a compact hero placeholder.
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
    );
  }
}
