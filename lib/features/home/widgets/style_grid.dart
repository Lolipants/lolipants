import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/widgets/region_style_button.dart';

/// Section header + vertical list of curated design entry points (Gulf, casual,
/// modern, Levant).
class StyleGrid extends StatelessWidget {
  /// Creates the home style strip.
  const StyleGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final shown = regionPresetsForHomeShowcase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.sectionFeaturedDesigns,
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      AppStrings.sectionFeaturedDesignsAr,
                      style: AppTextStyles.arabicBody.copyWith(
                        fontSize: 14,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/browse'),
              child: Text(
                '${AppStrings.seeAll} · ${AppStrings.seeAllAr}',
                style: AppTextStyles.labelGold.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final preset in shown) ...[
          RegionStyleButton(preset: preset),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
