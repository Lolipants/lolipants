import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/configurator_providers.dart';
import 'package:lolipants/features/editor/providers/editor_estimate_provider.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

/// One-line design summary + price under the hero preview.
class EditorDesignSummaryBar extends ConsumerWidget {
  const EditorDesignSummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final catalogAsync = ref.watch(configuratorCatalogProvider);
    final estimateAsync = ref.watch(editorEstimateProvider);

    if (editor.isWeddingTab) return const SizedBox.shrink();

    return catalogAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (catalog) {
        ConfiguratorTemplate? template;
        final selectedId = editor.configuratorTemplateId.trim();
        for (final t in catalog.templates) {
          if (t.id == selectedId) {
            template = t;
            break;
          }
        }
        template ??=
            catalog.templates.isNotEmpty ? catalog.templates.first : null;

        final summaryLine = template == null
            ? editor.designName.trim().isNotEmpty
                ? editor.designName.trim()
                : 'Your design'
            : configuratorSummaryLine(
                template: template,
                selections: editor.configuratorSelections,
              );

        final estimateLabel = estimateAsync.when(
          loading: () => null,
          error: (_, __) => null,
          data: (est) {
            if (est == null) return null;
            if (est.minTotal == est.maxTotal) {
              return 'From ${est.minTotal} ${est.currency}';
            }
            return 'From ${est.minTotal}–${est.maxTotal} ${est.currency}';
          },
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            2,
            AppSpacing.md,
            6,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.stone.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      summaryLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.sand,
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (estimateLabel != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      estimateLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
