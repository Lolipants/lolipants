import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_strings.dart';

/// Horizontal category filter chips (Phase 2 data).
class CategoryPills extends StatelessWidget {
  /// Creates a row of placeholder pills.
  const CategoryPills({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _pill(AppStrings.categoryAll),
          _pill('${AppStrings.categoryMen} · ${AppStrings.categoryMenAr}'),
          _pill('${AppStrings.categoryWomen} · ${AppStrings.categoryWomenAr}'),
        ],
      ),
    );
  }

  Widget _pill(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: AppColors.ember,
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
    );
  }
}
