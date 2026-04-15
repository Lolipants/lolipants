import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Featured collection promo card.
class FeaturedStrip extends StatelessWidget {
  /// Creates the featured strip.
  const FeaturedStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.featuredEyebrow, style: AppTextStyles.labelGold),
          const SizedBox(height: AppSpacing.sm),
          Text(AppStrings.featuredBody, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 12,
                height: 2,
                color: AppColors.gold,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppStrings.featuredCollection,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.gold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
