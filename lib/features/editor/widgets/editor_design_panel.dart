import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/logic/configurator_compat.dart';
import 'package:lolipants/features/editor/data/configurator_bundled_catalog.dart';
import 'package:lolipants/features/editor/logic/configurator_gender.dart';
import 'package:lolipants/features/editor/logic/mannequin_gender.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/configurator_providers.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/utils/layer_tint.dart';
import 'package:lolipants/features/editor/widgets/configurator_option_image.dart';
import 'package:lolipants/features/editor/widgets/editor_asset_thumb_card.dart';
import 'package:lolipants/features/editor/widgets/catalog_design_header.dart';
import 'package:lolipants/features/editor/widgets/catalog_design_picker.dart';
import 'package:lolipants/features/editor/widgets/editor_panel_header.dart';
import 'package:lolipants/features/editor/widgets/editor_studio_prompt_card.dart';
import 'package:lolipants/features/editor/widgets/editor_style_dropdown.dart';

/// Minimal configurator panel: pick a garment part, then choose an option.
class EditorDesignPanel extends ConsumerStatefulWidget {
  const EditorDesignPanel({
    super.key,
    this.height,
    this.onGenerateAi,
    this.embedded = false,
  });

  final double? height;
  final Future<void> Function()? onGenerateAi;
  final bool embedded;

  @override
  ConsumerState<EditorDesignPanel> createState() => _EditorDesignPanelState();
}

class _EditorDesignPanelState extends ConsumerState<EditorDesignPanel> {
  bool _aiExpanded = false;

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);
    final catalogAsync = ref.watch(configuratorCatalogProvider);
    final catalogTemplates =
        ref.watch(configuratorCatalogProvider).valueOrNull?.templates ??
            bundledConfiguratorCatalog().templates;
    final templates = ref.watch(mannequinConfiguratorTemplatesProvider);
    final catalogOnly = templates.isEmpty;
    final panelHeight = widget.height ??
        (MediaQuery.sizeOf(context).height * 0.36).clamp(260.0, 340.0);

    ref.listen<AsyncValue<ConfiguratorCatalog>>(configuratorCatalogProvider,
        (previous, next) {
      next.whenData((_) {
        ref.read(editorProvider.notifier).syncBuildLaneForMannequin(
              ref.read(mannequinConfiguratorTemplatesProvider),
            );
      });
    });

    final body = catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Could not load design catalogue.',
          style: AppTextStyles.bodySmall,
        ),
      ),
      data: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          notifier.syncBuildLaneForMannequin(templates);
        });

        if (catalogOnly || editor.buildStyleMode == EditorBuildStyleMode.catalog) {
          final allSections =
              ref.watch(mergedCatalogSectionsProvider(editor.mannequinId));
          final sections = filterCatalogSectionsByMode(
            allSections,
            editor.catalogFilter,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.embedded) ...[
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderDefault,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ],
              CatalogDesignHeader(
                templates: catalogTemplates,
                mannequinId: editor.mannequinId,
                template: catalogOnly ? null : _resolveTemplate(templates, editor),
                catalogOnly: catalogOnly,
                embedded: widget.embedded,
                onReset: catalogOnly
                    ? null
                    : () {
                        notifier.setConfiguratorSlotIndex(0);
                        notifier.resetCatalogBuild(editor.mannequinId);
                      },
              ),
              Expanded(
                child: _aiExpanded
                    ? _AiSection(
                        expanded: true,
                        onToggle: () => setState(() => _aiExpanded = false),
                        onGenerate: widget.onGenerateAi ?? () async {},
                      )
                    : CatalogDesignPicker(
                        sections: sections,
                        selectedRef: editor.selectedCatalogDesignPath,
                        onSelected: notifier.setCatalogDesignPath,
                      ),
              ),
              if (kFeatureAiEditorTab && !_aiExpanded)
                _AiSection(
                  expanded: false,
                  onToggle: () => setState(() => _aiExpanded = true),
                  onGenerate: widget.onGenerateAi ?? () async {},
                ),
            ],
          );
        }

        if (templates.isEmpty) {
          return Center(
            child: Text(
              AppStrings.editorBuildPickTemplate,
              style: AppTextStyles.bodyMedium,
            ),
          );
        }

        final template = _resolveTemplate(templates, editor);

        final slots = activeConfiguratorSlots(
          template: template,
          selections: editor.configuratorSelections,
        );
        if (slots.isEmpty) return const SizedBox.shrink();

        final slotIndex =
            editor.activeConfiguratorSlotIndex.clamp(0, slots.length - 1);
        final slot = slots[slotIndex];
        final selectedOptionId = editor.configuratorSelections[slot.id];
        final options = filteredOptionsForSlot(
          template: template,
          selections: editor.configuratorSelections,
          slot: slot,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.embedded) ...[
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderDefault,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],
            EditorPanelHeader(
              embedded: widget.embedded,
              leading: EditorStyleDropdown(
                templates: catalogTemplates,
                mannequinId: editor.mannequinId,
                selectedTemplateId: template.id,
                buildStyleMode: editor.buildStyleMode,
                dense: true,
                onReset: () {
                  notifier.setConfiguratorSlotIndex(0);
                  notifier.resetConfiguratorBuild(templates);
                },
              ),
              chips: [
                for (var index = 0; index < slots.length; index++)
                  EditorHeaderChipData(
                    label: slots[index].titleEn,
                    selected: slotIndex == index,
                    onTap: () => notifier.setConfiguratorSlotIndex(index),
                  ),
              ],
            ),
            Expanded(
              child: _aiExpanded
                  ? _AiSection(
                      expanded: true,
                      onToggle: () => setState(() => _aiExpanded = false),
                      onGenerate: widget.onGenerateAi ?? () async {},
                    )
                  : _OptionGrid(
                      template: template,
                      primaryColour: editor.primaryColour,
                      accentColour: editor.accentColour,
                      options: options,
                      selectedOptionId: selectedOptionId,
                      onPick: (optionId) => notifier.setConfiguratorOption(
                        template: template,
                        slotId: slot.id,
                        optionId: optionId,
                      ),
                    ),
            ),
            if (kFeatureAiEditorTab && !_aiExpanded)
              _AiSection(
                expanded: false,
                onToggle: () => setState(() => _aiExpanded = true),
                onGenerate: widget.onGenerateAi ?? () async {},
              ),
          ],
        );
      },
    );

    if (widget.embedded) return body;

    return SizedBox(
      height: panelHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.stone,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          border: const Border(top: BorderSide(color: AppColors.borderStrong)),
        ),
        child: body,
      ),
    );
  }

  ConfiguratorTemplate _resolveTemplate(
    List<ConfiguratorTemplate> templates,
    EditorState editor,
  ) {
    final selectedId = editor.configuratorTemplateId.trim();
    for (final t in templates) {
      if (t.id == selectedId) return t;
    }
    final lane = mannequinGenderLane(editor.mannequinId);
    return preferredConfiguratorTemplateForGender(templates, lane) ??
        templates.first;
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.template,
    required this.primaryColour,
    required this.accentColour,
    required this.options,
    required this.selectedOptionId,
    required this.onPick,
  });

  final ConfiguratorTemplate template;
  final Color primaryColour;
  final Color accentColour;
  final List<ConfiguratorOption> options;
  final String? selectedOptionId;
  final ValueChanged<String> onPick;

  static const double _spacing = 8;

  @override
  Widget build(BuildContext context) {
    const thumbW = EditorCompactThumbCard.thumbSize;
    const thumbH = EditorCompactThumbCard.stripHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerWidth = constraints.maxWidth - AppSpacing.md * 2 - _spacing;
        final columns = (innerWidth / (thumbW + _spacing)).floor().clamp(2, 6);

        if (options.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No options available for this combination.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: _spacing,
            crossAxisSpacing: _spacing,
            childAspectRatio: thumbW / thumbH,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final opt = options[index];
            final selected = selectedOptionId == opt.id;
            return EditorCompactThumbCard(
              label: opt.labelEn,
              selected: selected,
              onTap: () => onPick(opt.id),
              image: ConfiguratorOptionImage(
                option: opt,
                tintColor: resolveOptionTintColor(
                  option: opt,
                  template: template,
                  primaryColour: primaryColour,
                  accentColour: accentColour,
                ),
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            );
          },
        );
      },
    );
  }
}

class _AiSection extends StatelessWidget {
  const _AiSection({
    required this.expanded,
    required this.onToggle,
    required this.onGenerate,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final Future<void> Function() onGenerate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: expanded
            ? null
            : const Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    expanded ? Icons.arrow_back : Icons.chevron_right,
                    color: AppColors.fog,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    expanded ? 'Back to parts' : 'Enhance with AI',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: expanded ? AppColors.sand : AppColors.fog,
                      fontSize: 11,
                      fontWeight:
                          expanded ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: EditorStudioPromptCard(
                  compact: true,
                  onGenerate: onGenerate,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
