import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/providers/preset_providers.dart';
import 'package:lolipants/features/browse/widgets/region_style_button.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Phase 3 `/browse/:category` screen. Filters the regional preset catalogue
/// by a high-level category slug (men, women, kids, wedding, accessories) and
/// re-uses [RegionStyleButton] rows so tapping a preset opens the editor
/// pre-seeded the same way the home and browse screens do.
class CategoryDetailScreen extends ConsumerWidget {
  /// Creates the screen.
  const CategoryDetailScreen({required this.category, super.key});

  /// Category slug passed in from the router.
  final String category;

  /// Maps a category slug to the garment types considered part of it. The
  /// mapping is intentionally generous so "men" matches thobes, bishts, etc.
  static const Map<String, List<String>> _categoryGarments = {
    'all': <String>[],
    'men': ['thobe', 'bisht', 'kandura', 'dishdasha', 'jubbah', 'suit', 'coat'],
    'women': ['abaya', 'kaftan', 'dress', 'jalabiya'],
    'kids': ['dishdasha', 'kandura', 'thobe', 'dress'],
    'wedding': ['dress'],
    'accessories': <String>[],
  };

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
    if (key == 'casual') {
      return catalog.where((p) => p.isCasualStyle).toList(growable: false);
    }
    final garments = _categoryGarments[key] ?? const <String>[];
    if (garments.isEmpty) return catalog;
    return catalog
        .where((p) => garments.contains(p.garmentType))
        .toList(growable: false);
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
        title: Text(titleEn, style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: presets.isEmpty && key != 'accessories'
                ? _EmptyState(titleEn: titleEn)
                : presets.isEmpty && key == 'accessories'
                    ? _AccessoriesHub(
                        onDesignTshirt: () {
                          if (kFeatureCasual) {
                            context.push('/browse/c/casual');
                          }
                        },
                      )
                    : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.xxl,
                    ),
                    children: [
                      if (titleAr.isNotEmpty)
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            titleAr,
                            style: AppTextStyles.arabicLabel.copyWith(
                              fontSize: 13,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
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

class _AccessoriesHub extends StatelessWidget {
  const _AccessoriesHub({required this.onDesignTshirt});

  final VoidCallback onDesignTshirt;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          AppStrings.homeAccessoriesSubtitle,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (kFeatureCasual) ...[
          LolipantsButton(
            label: AppStrings.accessoriesTshirtCta,
            onPressed: onDesignTshirt,
          ),
          const SizedBox(height: AppSpacing.md),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              AppStrings.accessoriesTshirtCtaAr,
              style: AppTextStyles.arabicLabel.copyWith(fontSize: 12),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _AccessoryTile(
          icon: Icons.checkroom_outlined,
          title: 'Scarves & shawls',
          subtitle: 'Coming soon',
        ),
        const SizedBox(height: AppSpacing.md),
        _AccessoryTile(
          icon: Icons.shopping_bag_outlined,
          title: 'Bags',
          subtitle: 'Coming soon',
        ),
        const SizedBox(height: AppSpacing.md),
        _AccessoryTile(
          icon: Icons.watch_outlined,
          title: 'Jewellery & watches',
          subtitle: 'Coming soon',
        ),
      ],
    );
  }
}

class _AccessoryTile extends StatelessWidget {
  const _AccessoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.stone.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
