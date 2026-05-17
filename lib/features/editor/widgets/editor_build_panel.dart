import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/configurator_defaults.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/configurator_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/configurator_option_image.dart';
import 'package:lolipants/features/editor/widgets/editor_asset_thumb_card.dart';

/// Build tab: slot chips + large horizontal part picker (modest abaya default).
class EditorBuildPanel extends ConsumerStatefulWidget {
  const EditorBuildPanel({super.key, this.height});

  /// When set, caps panel height to fit the editor shell (avoids overflow).
  final double? height;

  @override
  ConsumerState<EditorBuildPanel> createState() => _EditorBuildPanelState();
}

class _EditorBuildPanelState extends ConsumerState<EditorBuildPanel> {
  int _slotIndex = 0;

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorProvider);
    final catalogAsync = ref.watch(configuratorCatalogProvider);
    final panelHeight = widget.height ??
        (MediaQuery.sizeOf(context).height * 0.40).clamp(280.0, 380.0);

    ref.listen<AsyncValue<ConfiguratorCatalog>>(configuratorCatalogProvider,
        (previous, next) {
      next.whenData((catalog) {
        ref
            .read(editorProvider.notifier)
            .ensureDefaultConfiguratorTemplate(catalog.templates);
      });
    });

    return SizedBox(
      height: panelHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.stone,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          border: const Border(top: BorderSide(color: AppColors.borderStrong)),
        ),
        child: catalogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(
              'Could not load build catalogue.',
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
              ref
                  .read(editorProvider.notifier)
                  .ensureDefaultConfiguratorTemplate(templates);
            });

            final selectedId = editor.configuratorTemplateId.trim();
            ConfiguratorTemplate? template;
            for (final t in templates) {
              if (t.id == selectedId) {
                template = t;
                break;
              }
            }
            template ??= templates.firstWhere(
              (t) => t.id == kDefaultConfiguratorTemplateId,
              orElse: () => templates.first,
            );

            final slots = template.slots;
            if (slots.isEmpty) {
              return const SizedBox.shrink();
            }
            final safeIndex = _slotIndex.clamp(0, slots.length - 1);
            if (safeIndex != _slotIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _slotIndex = safeIndex);
              });
            }
            final slot = slots[safeIndex];
            final selectedOptionId = editor.configuratorSelections[slot.id];
            ConfiguratorOption? selectedOption;
            for (final o in slot.options) {
              if (o.id == selectedOptionId) {
                selectedOption = o;
                break;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: slots.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 6),
                            itemBuilder: (context, index) {
                              final s = slots[index];
                              final picked =
                                  editor.configuratorSelections[s.id];
                              final label = picked == null
                                  ? s.titleEn
                                  : _labelForSlot(s, picked);
                              return _SlotChip(
                                label: label,
                                title: s.titleEn,
                                selected: index == safeIndex,
                                onTap: () => setState(() => _slotIndex = index),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _TemplateMenu(
                        templates: templates,
                        selectedId: template.id,
                      ),
                      IconButton(
                        tooltip: AppStrings.editorBuildReset,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () {
                          setState(() => _slotIndex = 0);
                          ref
                              .read(editorProvider.notifier)
                              .resetConfiguratorBuild(templates);
                        },
                        icon: const Icon(Icons.restart_alt, size: 20),
                        color: AppColors.fog,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    slot.titleEn,
                    style: AppTextStyles.labelGold.copyWith(fontSize: 11),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: _OptionStrip(
                    slot: slot,
                    selectedOptionId: selectedOptionId,
                    onPick: (optionId) =>
                        ref.read(editorProvider.notifier).setConfiguratorOption(
                              template: template!,
                              slotId: slot.id,
                              optionId: optionId,
                            ),
                  ),
                ),
                if (selectedOption != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      selectedOption.labelEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.sand,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _labelForSlot(ConfiguratorSlot slot, String optionId) {
    for (final o in slot.options) {
      if (o.id == optionId) {
        final short = o.labelEn.split(' ').first;
        return short.length > 10 ? '${short.substring(0, 9)}…' : short;
      }
    }
    return slot.titleEn;
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.18)
                : AppColors.smoke,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            selected ? title : label,
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

class _TemplateMenu extends ConsumerWidget {
  const _TemplateMenu({
    required this.templates,
    required this.selectedId,
  });

  final List<ConfiguratorTemplate> templates;
  final String selectedId;

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
      tooltip: AppStrings.editorBuildTemplate,
      color: AppColors.stone,
      initialValue: selectedId,
      onSelected: (id) {
        ref
            .read(editorProvider.notifier)
            .setConfiguratorTemplate(id, templates);
      },
      itemBuilder: (context) => [
        for (final t in templates)
          PopupMenuItem(
            value: t.id,
            child: Text(
              t.nameEn,
              style: AppTextStyles.bodySmall.copyWith(
                color: t.id == selectedId ? AppColors.gold : AppColors.sand,
              ),
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current?.nameEn ?? 'Template',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.fog,
                fontSize: 10,
              ),
            ),
            const Icon(Icons.expand_more, size: 18, color: AppColors.fog),
          ],
        ),
      ),
    );
  }
}

/// Vertically scrollable grid of compact square configurator thumbs.
class _OptionStrip extends StatelessWidget {
  const _OptionStrip({
    required this.slot,
    required this.selectedOptionId,
    required this.onPick,
  });

  final ConfiguratorSlot slot;
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

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: _spacing,
            crossAxisSpacing: _spacing,
            childAspectRatio: thumbW / thumbH,
          ),
          itemCount: slot.options.length,
          itemBuilder: (context, index) {
            final opt = slot.options[index];
            final selected = selectedOptionId == opt.id;
            return EditorCompactThumbCard(
              label: opt.labelEn,
              selected: selected,
              onTap: () => onPick(opt.id),
              image: ConfiguratorOptionImage(
                option: opt,
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
