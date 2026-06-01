import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/logic/configurator_gender.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

/// Popup menu value for the bundled flat-lay catalogue lane.
const String kCatalogBuildStyleValue = '__catalog__';

/// Popup menu value for reset build.
const String kResetBuildStyleValue = '__reset__';

/// Width of the style trigger so it does not shift when the label changes.
double editorStyleDropdownTriggerWidth({
  required List<ConfiguratorTemplate> laneTemplates,
  required bool catalogOnly,
  required bool dense,
}) {
  final labels = [
    for (final t in laneTemplates) t.nameEn,
    AppStrings.editorStyleCatalogMode,
  ];
  if (catalogOnly) {
    labels
      ..clear()
      ..add(AppStrings.editorStyleCatalogMode);
  }
  final textStyle = AppTextStyles.bodySmall.copyWith(
    color: dense ? AppColors.fog : AppColors.sand,
    fontSize: dense ? 10 : null,
  );
  final iconSize = dense ? 18.0 : 14.0;
  final horizontalPadding = dense ? 8.0 : 16.0;

  var maxTextWidth = 0.0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (painter.width > maxTextWidth) {
      maxTextWidth = painter.width;
    }
  }

  return maxTextWidth + iconSize + horizontalPadding;
}

/// Compact style menu: configurator templates + catalogue + reset.
class EditorStyleDropdown extends ConsumerWidget {
  const EditorStyleDropdown({
    required this.templates,
    required this.mannequinId,
    required this.selectedTemplateId,
    required this.buildStyleMode,
    this.catalogOnly = false,
    this.onReset,
    this.dense = false,
    this.compactMaxWidth,
    super.key,
  });

  final List<ConfiguratorTemplate> templates;
  final String mannequinId;
  final String selectedTemplateId;
  final EditorBuildStyleMode buildStyleMode;
  final bool catalogOnly;
  final VoidCallback? onReset;
  final bool dense;

  /// Caps trigger width in dense header rows (e.g. beside filter chips).
  final double? compactMaxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laneTemplates =
        configuratorTemplatesForMannequin(templates, mannequinId);
    final onlyCatalog = catalogOnly || laneTemplates.isEmpty;

    ConfiguratorTemplate? current;
    if (!onlyCatalog) {
      for (final t in laneTemplates) {
        if (t.id == selectedTemplateId) {
          current = t;
          break;
        }
      }
    }

    final label = onlyCatalog || buildStyleMode == EditorBuildStyleMode.catalog
        ? AppStrings.editorStyleCatalogMode
        : (current?.nameEn ?? 'Style');

    var triggerWidth = editorStyleDropdownTriggerWidth(
      laneTemplates: laneTemplates,
      catalogOnly: onlyCatalog,
      dense: dense,
    );
    if (dense && compactMaxWidth != null) {
      triggerWidth = triggerWidth.clamp(72, compactMaxWidth!);
    }

    final trigger = SizedBox(
      width: triggerWidth,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 4 : 8,
          vertical: dense ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: dense ? Colors.transparent : AppColors.smoke,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: dense ? null : Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: dense ? AppColors.fog : AppColors.sand,
                  fontSize: dense ? 10 : null,
                ),
              ),
            ),
            if (!onlyCatalog)
              Icon(
                Icons.expand_more,
                size: dense ? 18 : 14,
                color: AppColors.fog,
              ),
          ],
        ),
      ),
    );

    if (onlyCatalog) {
      return Tooltip(
        message: AppStrings.editorStyleCatalogMode,
        child: trigger,
      );
    }

    return PopupMenuButton<String>(
      tooltip: AppStrings.editorBuildChangeStyle,
      color: AppColors.stone,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      offset: const Offset(0, 36),
      onSelected: (value) {
        final notifier = ref.read(editorProvider.notifier);
        if (value == kResetBuildStyleValue) {
          onReset?.call();
          return;
        }
        if (value == kCatalogBuildStyleValue) {
          notifier.enterCatalogBuildMode(mannequinId);
          return;
        }
        notifier.setConfiguratorTemplate(value, laneTemplates);
      },
      itemBuilder: (context) => [
        for (final t in laneTemplates)
          PopupMenuItem(
            value: t.id,
            child: Text(
              t.nameEn,
              style: AppTextStyles.bodySmall.copyWith(
                color: buildStyleMode == EditorBuildStyleMode.configurator &&
                        t.id == selectedTemplateId
                    ? AppColors.gold
                    : AppColors.sand,
                fontWeight:
                    buildStyleMode == EditorBuildStyleMode.configurator &&
                            t.id == selectedTemplateId
                        ? FontWeight.w600
                        : FontWeight.w400,
              ),
            ),
          ),
        PopupMenuItem(
          value: kCatalogBuildStyleValue,
          child: Text(
            AppStrings.editorStyleCatalogMode,
            style: AppTextStyles.bodySmall.copyWith(
              color: buildStyleMode == EditorBuildStyleMode.catalog
                  ? AppColors.gold
                  : AppColors.sand,
              fontWeight: buildStyleMode == EditorBuildStyleMode.catalog
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
        if (onReset != null)
          PopupMenuItem(
            value: kResetBuildStyleValue,
            child: Text(
              AppStrings.editorBuildReset,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
            ),
          ),
      ],
      child: trigger,
    );
  }
}
