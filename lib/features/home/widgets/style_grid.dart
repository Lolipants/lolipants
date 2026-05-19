import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/providers/preset_providers.dart';
import 'package:lolipants/features/browse/widgets/featured_design_carousel.dart';

/// Home featured designs — scrollable two-column grid.
class StyleGrid extends ConsumerWidget {
  const StyleGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pool =
        ref.watch(presetCatalogProvider).valueOrNull ?? regionPresetsForHomeGrid();
    final shown = regionPresetsForHomeShowcase(pool);
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
