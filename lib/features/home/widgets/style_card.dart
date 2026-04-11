import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Compact garment preview tile for home grids.
class StyleCard extends StatelessWidget {
  /// Qatari thobe preset.
  const StyleCard.qatariThobe({super.key})
      : title = AppStrings.styleQatariThobe,
        subtitle = AppStrings.originGulf,
        imageColor = const Color(0xFF3D2B4F);

  /// Saudi bisht preset.
  const StyleCard.saudiBisht({super.key})
      : title = AppStrings.styleSaudiBisht,
        subtitle = AppStrings.originGulf,
        imageColor = const Color(0xFF1F4D3A);

  /// UAE kandura preset.
  const StyleCard.uaeKandura({super.key})
      : title = AppStrings.styleUaeKandura,
        subtitle = AppStrings.originGulf,
        imageColor = const Color(0xFFB08D3A);

  /// Omani dishdasha preset.
  const StyleCard.omaniDishdasha({super.key})
      : title = AppStrings.styleOmaniDishdasha,
        subtitle = AppStrings.originGulf,
        imageColor = const Color(0xFF1B4A42);

  /// Primary garment title.
  final String title;

  /// Secondary origin or region line.
  final String subtitle;

  /// Placeholder swatch behind the image strip.
  final Color imageColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: imageColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
