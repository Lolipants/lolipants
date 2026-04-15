import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Tappable bilingual category chips for the home feed.
class CategoryPills extends StatefulWidget {
  /// Creates category pills.
  const CategoryPills({super.key});

  @override
  State<CategoryPills> createState() => _CategoryPillsState();
}

class _CategoryPillsState extends State<CategoryPills> {
  int _selected = 0;

  static const _labels = <(String en, String ar)>[
    (AppStrings.categoryAll, ''),
    (AppStrings.categoryMen, AppStrings.categoryMenAr),
    (AppStrings.categoryWomen, AppStrings.categoryWomenAr),
    (AppStrings.categoryKids, AppStrings.categoryKidsAr),
    (AppStrings.categoryWedding, ''),
    (AppStrings.categoryAccessories, ''),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_labels.length, (i) {
          final (en, ar) = _labels[i];
          final selected = i == _selected;
          final label = ar.isEmpty ? en : '$en · $ar';
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? AppColors.ink : AppColors.sand,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: selected,
              onSelected: (_) => setState(() => _selected = i),
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
