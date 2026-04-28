import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Tappable bilingual category chips for the home feed. Tapping a non-"All"
/// pill twice (or any already-selected pill) navigates to the category
/// detail browse screen; the first tap just sets the active filter locally.
class CategoryPills extends StatefulWidget {
  /// Creates category pills.
  const CategoryPills({super.key});

  @override
  State<CategoryPills> createState() => _CategoryPillsState();
}

class _CategoryPillsState extends State<CategoryPills> {
  static const _allLabels = <(String en, String ar, String slug)>[
    (AppStrings.categoryAll, '', 'all'),
    (AppStrings.categoryMen, AppStrings.categoryMenAr, 'men'),
    (AppStrings.categoryWomen, AppStrings.categoryWomenAr, 'women'),
    (AppStrings.categoryKids, AppStrings.categoryKidsAr, 'kids'),
    (AppStrings.categoryWedding, '', 'wedding'),
    (AppStrings.categoryAccessories, '', 'accessories'),
  ];

  String _selectedSlug = 'all';

  @override
  Widget build(BuildContext context) {
    final labels = kFeatureMens
        ? _allLabels
        : _allLabels.where((e) => e.$3 != 'men').toList(growable: false);
    final activeSlug =
        labels.any((e) => e.$3 == _selectedSlug) ? _selectedSlug : 'all';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final (en, ar, slug) = labels[i];
          final selected = activeSlug == slug;
          final label = ar.isEmpty ? en : '$en · $ar';
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? AppColors.ink : AppColors.sand,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: selected,
              onSelected: (_) {
                if (selected && slug != 'all') {
                  context.push('/browse/c/$slug');
                  return;
                }
                setState(() => _selectedSlug = slug);
              },
              selectedColor: AppColors.gold,
              backgroundColor: AppColors.stone,
              side: const BorderSide(color: AppColors.borderSubtle),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
          );
        }),
      ),
    );
  }
}
