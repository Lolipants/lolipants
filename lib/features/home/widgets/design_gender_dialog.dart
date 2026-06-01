import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Asks the shopper to pick women or men when profile gender is unset.
///
/// Returns [UserGenderPreference.women] or [UserGenderPreference.men], or
/// null when dismissed.
Future<String?> showDesignGenderDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return const _DesignGenderDialog();
    },
  );
}

class _DesignGenderDialog extends ConsumerWidget {
  const _DesignGenderDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final isAr = locale.languageCode == 'ar';

    final title = localizedFromLocale(
      locale,
      AppStrings.designGenderDialogTitle,
      AppStrings.designGenderDialogTitleAr,
    );
    final body = localizedFromLocale(
      locale,
      AppStrings.designGenderDialogBody,
      AppStrings.designGenderDialogBodyAr,
    );
    final womenLabel = localizedFromLocale(
      locale,
      AppStrings.homeCategoryWomen,
      AppStrings.homeCategoryWomenAr,
    );
    final menLabel = localizedFromLocale(
      locale,
      AppStrings.homeCategoryMen,
      AppStrings.homeCategoryMenAr,
    );

    return AlertDialog(
      backgroundColor: AppColors.stone,
      title: Text(title, style: AppTextStyles.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          isAr
              ? Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(body, style: AppTextStyles.arabicBody),
                )
              : Text(body, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(
              UserGenderPreference.women,
            ),
            child: Text(womenLabel),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(
              UserGenderPreference.men,
            ),
            child: Text(menLabel),
          ),
        ],
      ),
    );
  }
}
