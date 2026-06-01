import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/preset_gender_filter.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/providers/preset_providers.dart';
import 'package:lolipants/features/browse/widgets/region_style_button.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';
import 'package:lolipants/features/accessories/screens/accessories_browse_section.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/core/l10n/app_localization.dart';

/// Phase 3 `/browse/:category` screen. Filters the regional preset catalogue
/// by a high-level category slug (men, women, kids, wedding, accessories) and
/// re-uses [RegionStyleButton] rows so tapping a preset opens the editor
/// pre-seeded the same way the home and browse screens do.
class CategoryDetailScreen extends ConsumerWidget {
  /// Creates the screen.
  const CategoryDetailScreen({required this.category, super.key});

  /// Category slug passed in from the router.
  final String category;

  static const Map<String, String> _categoryTitles = {
    'all': 'All designs',
    'men': 'Men',
    'women': 'Women',
    'kids': 'Kids',
    'wedding': 'Wedding',
    'accessories': 'Accessories',
    'casual': 'Casual & T-shirts',
  };

  static const Map<String, String> _categoryTitlesAr = {
    'all': 'جميع التصاميم',
    'men': 'رجال',
    'women': 'نساء',
    'kids': 'أطفال',
    'wedding': 'عرس',
    'accessories': 'إكسسوارات',
    'casual': 'كاجوال وقمصان',
  };

  static List<RegionStylePreset> _presetsForCategory(
    String key,
    List<RegionStylePreset> catalog,
  ) {
    if (key == 'wedding') {
      return catalog
          .where((p) => p.garmentType == 'dress')
          .toList(growable: false);
    }
    if (key == 'accessories' || key == 'all') return catalog;
    return presetsForBrowseCategorySlug(key, catalog);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = category.toLowerCase().trim();
    if (!kFeatureCasual && key == 'casual') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/browse');
      });
      return const SizedBox.shrink();
    }
    if (!kFeatureMens && (key == 'men' || key == 'kids')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/browse');
      });
      return const SizedBox.shrink();
    }
    final catalog =
        ref.watch(presetCatalogProvider).valueOrNull ?? regionPresetsForHomeGrid();
    final presets = _presetsForCategory(key, catalog);
    final titleEn = _categoryTitles[key] ?? 'Browse';
    final titleAr = _categoryTitlesAr[key] ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.gold),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/browse');
            }
          },
        ),
        title: Text(
          localizedFromContext(context, titleEn, titleAr.isNotEmpty ? titleAr : titleEn),
          style: AppTextStyles.titleLarge,
        ),
        backgroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: key == 'accessories'
                ? AccessoriesBrowseSection(
                    onDesignTshirt: () {
                      if (kFeatureCasual) {
                        context.push('/browse/c/casual');
                      }
                    },
                  )
                : presets.isEmpty
                ? _EmptyState(titleEn: titleEn)
                    : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.xxl,
                    ),
                    children: [
                      if (key == 'wedding' && kFeatureWeddingTab) ...[
                        LolipantsButton(
                          label: 'Wedding & bridesmaid dresses',
                          onPressed: () => context.push(
                            '/editor',
                            extra: const EditorBootstrapArgs(
                              source: 'browse_wedding',
                              initialTab: 'wedding',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Regional styles',
                          style: AppTextStyles.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      for (final preset in presets) ...[
                        RegionStyleButton(
                          preset: preset,
                          onTap: () =>
                              context.push('/browse/style/${preset.id}'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.titleEn});

  final String titleEn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'No styles yet for $titleEn.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}
