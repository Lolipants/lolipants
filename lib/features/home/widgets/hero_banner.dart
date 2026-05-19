import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Home hero card: AI designer CTA with bilingual copy.
class HeroBanner extends StatelessWidget {
  /// Creates the hero card.
  const HeroBanner({
    required this.onTryNow,
    super.key,
  });

  /// Fired when the primary CTA is pressed.
  final VoidCallback onTryNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.stone,
            AppColors.stone.withValues(alpha: 0.85),
            AppColors.ink.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.heroAiDesigner,
                  style: AppTextStyles.labelGold.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.heroDreamOutfit,
                  style: AppTextStyles.titleMedium.copyWith(height: 1.2),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppStrings.tagline,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.fog,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          TextButton(
            onPressed: onTryNow,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.gold,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
            child: Text(
              AppStrings.heroTryNow,
              style: AppTextStyles.labelGold.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
