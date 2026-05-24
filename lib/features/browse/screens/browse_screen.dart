import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/providers/preset_providers.dart';
import 'package:lolipants/features/browse/widgets/featured_design_carousel.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Region and casual browse hub with a vertical featured design grid.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  String? _pill;
  bool _pillSyncedToCatalog = false;

  @override
  Widget build(BuildContext context) {
    final presetCatalog = ref.watch(genderFilteredPresetsProvider);
    final source = presetCatalog;
    if (!_pillSyncedToCatalog && presetCatalog.isNotEmpty) {
      _pill = defaultBrowseCatalogPill(source);
      _pillSyncedToCatalog = true;
    }
    _pill ??= defaultBrowseCatalogPill(source);
    final presets = regionPresetsForBrowsePill(_pill!, source);

    return Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrowseHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  _BrowsePillsRow(
                    selected: _pill!,
                    onChanged: (v) => setState(() => _pill = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: FeaturedDesignsSection(
                            presets: presets,
                            showHeader: false,
                            fillHeight: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _BrowseFooterNote(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseHeader extends StatelessWidget {
  const _BrowseHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.browseHeader,
          style: AppTextStyles.titleLarge.copyWith(
            letterSpacing: 0.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.chooseYourRegion,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
        ),
      ],
    );
  }
}

class _BrowseFooterNote extends StatelessWidget {
  const _BrowseFooterNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.featuredCollection,
      style: AppTextStyles.labelGold.copyWith(
        fontSize: 11,
        letterSpacing: 0.6,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: on ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: on
                ? Colors.transparent
                : AppColors.borderDefault.withValues(alpha: 0.7),
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
              fontWeight: on ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
