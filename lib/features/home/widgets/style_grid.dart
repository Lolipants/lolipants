import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/providers/preset_providers.dart';
import 'package:lolipants/features/browse/widgets/region_style_button.dart';

/// Section header + vertical list of traditional style long-buttons.
class StyleGrid extends ConsumerWidget {
  const StyleGrid({super.key});

  static const int _maxOnHome = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetsAsync = ref.watch(presetCatalogProvider);
    final presets = presetsAsync.valueOrNull ?? regionPresetsForHomeGrid();
    final shown = presets.take(_maxOnHome).toList(growable: false);
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
                    AppStrings.sectionTraditionalStyles,
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      AppStrings.sectionTraditionalStylesAr,
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
