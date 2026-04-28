import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/widgets/region_style_button.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Phase 3 `/browse/:category` screen. Filters the regional preset catalogue
/// by a high-level category slug (men, women, kids, wedding, accessories) and
/// re-uses [RegionStyleButton] rows so tapping a preset opens the editor
/// pre-seeded the same way the home and browse screens do.
class CategoryDetailScreen extends StatelessWidget {
  /// Creates the screen.
  const CategoryDetailScreen({required this.category, super.key});

  /// Category slug passed in from the router.
  final String category;

  /// Maps a category slug to the garment types considered part of it. The
  /// mapping is intentionally generous so "men" matches thobes, bishts, etc.
  static const Map<String, List<String>> _categoryGarments = {
    'all': <String>[],
    'men': ['thobe', 'bisht', 'kandura', 'dishdasha', 'jubbah', 'suit'],
    'women': ['abaya', 'kaftan', 'dress', 'jalabiya'],
    'kids': ['dishdasha', 'kandura', 'thobe', 'dress'],
    'wedding': ['bisht', 'kaftan', 'dress', 'djellaba'],
    'accessories': <String>[],
  };

  static const Map<String, String> _categoryTitles = {
    'all': 'All traditional styles',
    'men': 'Men',
    'women': 'Women',
    'kids': 'Kids',
    'wedding': 'Wedding',
    'accessories': 'Accessories',
  };

  static const Map<String, String> _categoryTitlesAr = {
    'all': 'جميع الأزياء التقليدية',
    'men': 'رجال',
    'women': 'نساء',
    'kids': 'أطفال',
    'wedding': 'عرس',
    'accessories': 'إكسسوارات',
  };

  @override
  Widget build(BuildContext context) {
    final key = category.toLowerCase().trim();
    final garments = _categoryGarments[key] ?? const <String>[];
    final presets = garments.isEmpty
        ? kRegionPresets
        : kRegionPresets
            .where((p) => garments.contains(p.garmentType))
            .toList(growable: false);
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
            child: presets.isEmpty
                ? _EmptyState(titleEn: titleEn)
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
