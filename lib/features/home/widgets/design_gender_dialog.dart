import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';

/// Asks the shopper to pick women or men when profile gender is unset.
///
/// Returns [UserGenderPreference.women] or [UserGenderPreference.men], or
/// null when dismissed.
Future<String?> showDesignGenderDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.stone,
        title: Text(
          AppStrings.designGenderDialogTitle,
          style: AppTextStyles.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.designGenderDialogBody,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                AppStrings.designGenderDialogBodyAr,
                style: AppTextStyles.arabicBody,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                UserGenderPreference.women,
              ),
              child: Text(AppStrings.homeCategoryWomen),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                UserGenderPreference.men,
              ),
              child: Text(AppStrings.homeCategoryMen),
            ),
          ],
        ),
      );
    },
  );
}
