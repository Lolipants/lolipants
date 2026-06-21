import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Body reference for AI refine: bundled mannequin or user photo.
enum RefineBodyReference {
  mannequin,
  customPhoto,
}

/// Asks how AI should reference the wearer's body before refining.
Future<RefineBodyReference?> showRefineBodyReferenceSheet(
  BuildContext context,
  WidgetRef ref,
) {
  final locale = ref.read(settingsLocaleProvider);
  final isAr = locale.languageCode == 'ar';

  return showModalBottomSheet<RefineBodyReference>(
    context: context,
    backgroundColor: AppColors.stone,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizedFromLocale(
                  locale,
                  AppStrings.refineBodyReferenceTitle,
                  AppStrings.refineBodyReferenceTitleAr,
                ),
                style: (isAr
                        ? AppTextStyles.titleSmall.copyWith(
                            fontFamily: AppTextStyles.arabicBody.fontFamily,
                          )
                        : AppTextStyles.titleSmall)
                    .copyWith(color: AppColors.sand),
                textAlign: TextAlign.center,
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              ),
              const SizedBox(height: AppSpacing.md),
              _RefineBodyReferenceTile(
                icon: Icons.accessibility_new_outlined,
                title: localizedFromLocale(
                  locale,
                  AppStrings.refineBodyReferenceMannequin,
                  AppStrings.refineBodyReferenceMannequinAr,
                ),
                subtitle: localizedFromLocale(
                  locale,
                  AppStrings.refineBodyReferenceMannequinBody,
                  AppStrings.refineBodyReferenceMannequinBodyAr,
                ),
                isAr: isAr,
                onTap: () => Navigator.of(sheetContext)
                    .pop(RefineBodyReference.mannequin),
              ),
              const SizedBox(height: AppSpacing.sm),
              _RefineBodyReferenceTile(
                icon: Icons.add_a_photo_outlined,
                title: localizedFromLocale(
                  locale,
                  AppStrings.mannequinUploadPhotoCta,
                  AppStrings.mannequinUploadPhotoCtaAr,
                ),
                subtitle: localizedFromLocale(
                  locale,
                  AppStrings.refineBodyReferencePhotoBody,
                  AppStrings.refineBodyReferencePhotoBodyAr,
                ),
                isAr: isAr,
                onTap: () => Navigator.of(sheetContext)
                    .pop(RefineBodyReference.customPhoto),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RefineBodyReferenceTile extends StatelessWidget {
  const _RefineBodyReferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isAr,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isAr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textDir = isAr ? TextDirection.rtl : TextDirection.ltr;
    return Material(
      color: AppColors.smoke,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Directionality(
            textDirection: textDir,
            child: Row(
              children: [
                Icon(icon, color: AppColors.gold, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.sand,
                          fontWeight: FontWeight.w600,
                          fontFamily: isAr
                              ? AppTextStyles.arabicBody.fontFamily
                              : null,
                        ),
                        textAlign:
                            isAr ? TextAlign.right : TextAlign.left,
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
                        textAlign:
                            isAr ? TextAlign.right : TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
