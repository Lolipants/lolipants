import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/browse/widgets/featured_design_carousel.dart';
import 'package:lolipants/features/home/providers/home_featured_presets_provider.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Gender-filtered horizontal featured designs on the home tab.
class HomeFeaturedSection extends ConsumerWidget {
  const HomeFeaturedSection({super.key});

  static const double _tileWidth = 140;
  static const double _tileHeight = 190;
  static const double _stripHeight = 218;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(homeFeaturedPresetsProvider);
    if (presets.isEmpty) return const SizedBox.shrink();

    final locale = ref.watch(settingsLocaleProvider);
    final gender = ref.watch(effectiveHomeFeaturedGenderProvider);
    final isAr = locale.languageCode == 'ar';
    final subtitle = AppStrings.homeFeaturedSubtitle(locale, gender);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        0,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        localizedFromLocale(
                          locale,
                          AppStrings.sectionFeaturedDesigns,
                          AppStrings.sectionFeaturedDesignsAr,
                        ),
                        style: (isAr
                                ? AppTextStyles.titleMedium.copyWith(
                                    fontFamily:
                                        AppTextStyles.arabicBody.fontFamily,
                                  )
                                : AppTextStyles.titleMedium)
                            .copyWith(
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w500,
                          color: AppColors.sand,
                        ),
                        textDirection:
                            isAr ? TextDirection.rtl : TextDirection.ltr,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.fog,
                          fontFamily: isAr
                              ? AppTextStyles.arabicBody.fontFamily
                              : null,
                        ),
                        textDirection:
                            isAr ? TextDirection.rtl : TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/browse'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    localizedFromLocale(
                      locale,
                      AppStrings.seeAll,
                      AppStrings.seeAllAr,
                    ),
                    style: AppTextStyles.labelGold.copyWith(
                      fontSize: 12,
                      letterSpacing: 0.4,
                      fontFamily: isAr
                          ? AppTextStyles.arabicBody.fontFamily
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: _stripHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              itemCount: presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => FeaturedDesignTile(
                preset: presets[index],
                width: _tileWidth,
                height: _tileHeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
