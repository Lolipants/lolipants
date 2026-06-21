import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/editor/data/render_preview_repository.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Compact floating refine control on the hero preview with quota indicator.
class EditorRefineFab extends ConsumerWidget {
  const EditorRefineFab({
    required this.onPressed,
    super.key,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final locale = ref.watch(settingsLocaleProvider);
    final quotaAsync = ref.watch(aiRenderQuotaProvider);
    final quota = quotaAsync.valueOrNull;
    final fabricOk =
        !editor.requiresFabricSelection || editor.isFabricSelected;
    final generating = editor.lookGenerating;
    final hasQuota = quota == null || quota.canRender;
    final enabled =
        fabricOk && !generating && hasQuota && onPressed != null;

    final quotaLabel = _quotaCompactLabel(quota);
    final tooltip = !fabricOk
        ? localizedFromLocale(
            locale,
            AppStrings.editorPickFabricForRefine,
            AppStrings.editorPickFabricForRefineAr,
          )
        : !hasQuota
            ? localizedFromLocale(
                locale,
                AppStrings.editorAiRenderQuotaTooltip,
                AppStrings.editorAiRenderQuotaTooltipAr,
              )
            : localizedFromLocale(
                locale,
                AppStrings.editorRefineTooltip,
                AppStrings.editorRefineTooltipAr,
              );

    final isAr = locale.languageCode == 'ar';
    final refineLabel = localizedFromLocale(
      locale,
      AppStrings.editorRefineLabel,
      AppStrings.editorRefineLabelAr,
    );

    return Positioned(
      right: 8,
      bottom: 8,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: enabled
              ? AppColors.gold
              : AppColors.stone.withValues(alpha: 0.92),
          elevation: enabled ? 4 : 0,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: enabled ? AppColors.gold : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (generating)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ink,
                      ),
                    )
                  else
                    Icon(
                      enabled ? Icons.auto_awesome : Icons.lock_outline,
                      size: 16,
                      color: enabled ? AppColors.ink : AppColors.fog,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    refineLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: enabled ? AppColors.ink : AppColors.fog,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      fontFamily: isAr
                          ? AppTextStyles.arabicBody.fontFamily
                          : null,
                    ),
                    textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (enabled && hasQuota)
                          ? AppColors.ink.withValues(alpha: 0.12)
                          : AppColors.ruby.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      quotaLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: (enabled && hasQuota)
                            ? AppColors.ink
                            : AppColors.rubyLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _quotaCompactLabel(AiRenderQuota? quota) {
    if (quota == null) return '…';
    return '${quota.remaining}/${quota.limit}';
  }
}
