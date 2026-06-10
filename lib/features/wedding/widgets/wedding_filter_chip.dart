import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

class WeddingFilterChip extends StatelessWidget {
  const WeddingFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.stone,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.borderDefault,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelGold.copyWith(
              color: selected ? AppColors.gold : AppColors.fog,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
