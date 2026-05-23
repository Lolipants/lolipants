import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/configurator_defaults.dart';
import 'package:lolipants/features/editor/logic/configurator_compat.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/configurator_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/utils/layer_tint.dart';
import 'package:lolipants/features/editor/widgets/configurator_option_image.dart';
import 'package:lolipants/features/editor/widgets/editor_asset_thumb_card.dart';
import 'package:lolipants/features/editor/widgets/editor_studio_prompt_card.dart';

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
    final panelHeight = widget.height ??
        (MediaQuery.sizeOf(context).height * 0.36).clamp(260.0, 340.0);

    ref.listen<AsyncValue<ConfiguratorCatalog>>(configuratorCatalogProvider,
        (previous, next) {
      next.whenData((catalog) {
        ref
            .read(editorProvider.notifier)
            .ensureDefaultConfiguratorTemplate(catalog.templates);
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
      data: (catalog) {
        final templates = catalog.templates;
        if (templates.isEmpty) {
          return Center(
            child: Text(
              AppStrings.editorBuildPickTemplate,
              style: AppTextStyles.bodyMedium,
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          notifier.ensureDefaultConfiguratorTemplate(templates);
        });

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
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                widget.embedded ? AppSpacing.xs : AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    _StyleMenu(
                      templates: templates,
                      selectedId: template.id,
                      onReset: () {
                        notifier.setConfiguratorSlotIndex(0);
                        notifier.resetConfiguratorBuild(templates);
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: slots.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 4),
                        itemBuilder: (context, index) {
                          final s = slots[index];
                          final selected = slotIndex == index;
                          return _SlotTab(
                            label: s.titleEn,
                            selected: selected,
                            onTap: () =>
                                notifier.setConfiguratorSlotIndex(index),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
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
    return templates.firstWhere(
      (t) => t.id == kDefaultConfiguratorTemplateId,
      orElse: () => templates.first,
    );
  }
}

/// Garment style picker + reset in one compact menu.
class _StyleMenu extends ConsumerWidget {
  const _StyleMenu({
    required this.templates,
    required this.selectedId,
    required this.onReset,
  });

  final List<ConfiguratorTemplate> templates;
  final String selectedId;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ConfiguratorTemplate? current;
    for (final t in templates) {
      if (t.id == selectedId) {
        current = t;
        break;
      }
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
        if (value == '__reset__') {
          onReset();
          return;
        }
        ref
            .read(editorProvider.notifier)
            .setConfiguratorTemplate(value, templates);
      },
      itemBuilder: (context) => [
        for (final t in templates)
          PopupMenuItem(
            value: t.id,
            child: Text(
              t.nameEn,
              style: AppTextStyles.bodySmall.copyWith(
                color: t.id == selectedId ? AppColors.gold : AppColors.sand,
                fontWeight:
                    t.id == selectedId ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: '__reset__',
          child: Text(
            AppStrings.editorBuildReset,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.smoke,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current?.nameEn ?? 'Style',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.sand,
                fontSize: 10,
              ),
            ),
            const Icon(Icons.expand_more, size: 14, color: AppColors.fog),
          ],
        ),
      ),
    );
  }
}

class _SlotTab extends StatelessWidget {
  const _SlotTab({
    required this.label,
    required this.selected,
    required this.onTap,
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
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.gold : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: selected ? AppColors.gold : AppColors.fog,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
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
