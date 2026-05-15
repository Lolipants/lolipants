import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/providers/preset_providers.dart';
import 'package:lolipants/features/browse/widgets/featured_strip.dart';
import 'package:lolipants/features/browse/widgets/region_style_button.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Region and casual browse hub: Gulf, Levant, Maghreb, Modern, Casual.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late String _pill;

  @override
  void initState() {
    super.initState();
    _pill = defaultBrowseCatalogPill();
  }

  @override
  Widget build(BuildContext context) {
    final presetCatalog = ref.watch(presetCatalogProvider).valueOrNull;
    final source = presetCatalog ?? regionPresetsForHomeGrid();
    final presets = regionPresetsForBrowsePill(_pill, source);
    return Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            AppStrings.browseHeaderAr,
                            style: AppTextStyles.arabicLabel.copyWith(
                              fontSize: 13,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        Text(
                          AppStrings.browseHeader,
                          style: AppTextStyles.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AppStrings.chooseYourRegion,
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _BrowsePillsRow(
                          selected: _pill,
                          onChanged: (v) => setState(() => _pill = v),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        for (final preset in presets) ...[
                          RegionStyleButton(preset: preset),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        const FeaturedStrip(),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowsePillsRow extends StatelessWidget {
  const _BrowsePillsRow({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final pills = <(String, String)>[
      ('gulf', 'Gulf'),
      ('levant', 'Levant'),
      ('maghreb', 'Maghreb'),
      ('modern', 'Modern'),
      if (kFeatureCasual) ('casual', 'Casual'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in pills) ...[
            _Pill(
              label: entry.$2,
              on: entry.$1 == selected,
              onTap: () => onChanged(entry.$1),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: on ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: on ? Colors.transparent : AppColors.borderDefault,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: on ? AppColors.ink : AppColors.fog,
            ),
          ),
        ),
      ),
    );
  }
}
