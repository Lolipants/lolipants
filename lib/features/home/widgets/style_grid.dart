import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/widgets/featured_design_carousel.dart';

/// Home featured designs — scrollable two-column grid.
class StyleGrid extends StatelessWidget {
  const StyleGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final shown = regionPresetsForHomeShowcase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FeaturedDesignsSection(
            presets: shown,
            fillHeight: true,
            onSeeAll: () => context.go('/browse'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.featuredCollection,
          style: AppTextStyles.labelGold.copyWith(
            fontSize: 11,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}
