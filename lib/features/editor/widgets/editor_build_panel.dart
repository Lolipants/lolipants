import 'dart:ui' show Locale;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/l10n/localized_label.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/data/configurator_bundled_catalog.dart';
import 'package:lolipants/features/editor/logic/configurator_compat.dart';
import 'package:lolipants/features/editor/logic/configurator_gender.dart';
import 'package:lolipants/features/editor/logic/mannequin_gender.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/configurator_providers.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/utils/layer_tint.dart';
import 'package:lolipants/features/editor/widgets/catalog_design_header.dart';
import 'package:lolipants/features/editor/widgets/catalog_design_picker.dart';
import 'package:lolipants/features/editor/widgets/configurator_option_image.dart';
import 'package:lolipants/features/editor/widgets/editor_asset_thumb_card.dart';
import 'package:lolipants/features/editor/widgets/editor_style_dropdown.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

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
    final locale = ref.watch(settingsLocaleProvider);
    final editor = ref.watch(editorProvider);
    final catalogAsync = ref.watch(configuratorCatalogProvider);
    final catalogTemplates =
        ref.watch(configuratorCatalogProvider).valueOrNull?.templates ??
            bundledConfiguratorCatalog().templates;
    final templates = ref.watch(mannequinConfiguratorTemplatesProvider);
    final catalogOnly = templates.isEmpty;
    final panelHeight = widget.height ??
        (MediaQuery.sizeOf(context).height * 0.40).clamp(280.0, 380.0);

    ref.listen<AsyncValue<ConfiguratorCatalog>>(configuratorCatalogProvider,
        (previous, next) {
      next.whenData((_) {
        ref.read(editorProvider.notifier).syncBuildLaneForMannequin(
              ref.read(mannequinConfiguratorTemplatesProvider),
            );
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
              localizedFromLocale(
                locale,
                AppStrings.editorBuildCatalogError,
                AppStrings.editorBuildCatalogErrorAr,
              ),
              style: AppTextStyles.bodySmall,
            ),
          ),
          data: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ref
                  .read(editorProvider.notifier)
                  .syncBuildLaneForMannequin(templates);
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
                  CatalogDesignHeader(
                    templates: catalogTemplates,
                    mannequinId: editor.mannequinId,
                    catalogOnly: catalogOnly,
                    onReset: catalogOnly
                        ? null
                        : () {
                            setState(() => _slotIndex = 0);
                            ref
                                .read(editorProvider.notifier)
                                .resetCatalogBuild(editor.mannequinId);
                          },
                  ),
                  Expanded(
                    child: CatalogDesignPicker(
                      sections: sections,
                      selectedRef: editor.selectedCatalogDesignPath,
                      onSelected: ref
                          .read(editorProvider.notifier)
                          .setCatalogDesignPath,
                    ),
                  ),
                ],
              );
            }

            if (templates.isEmpty) {
              return Center(
                child: Text(
                  localizedFromLocale(
                    locale,
                    AppStrings.editorBuildPickTemplate,
                    AppStrings.editorBuildPickTemplateAr,
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
              );
            }

            final selectedId = editor.configuratorTemplateId.trim();
            ConfiguratorTemplate? template;
            for (final t in templates) {
              if (t.id == selectedId) {
                template = t;
                break;
              }
            }
            template ??=
                preferredConfiguratorTemplateForGender(
                  templates,
                  mannequinGenderLane(editor.mannequinId),
                ) ??
                templates.first;
            final activeTemplate = template;

            final slots = activeConfiguratorSlots(
              template: activeTemplate,
              selections: editor.configuratorSelections,
            );
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
                              final slotTitle = localizedLabel(
                                locale,
                                en: s.titleEn,
                                ar: s.titleAr.trim().isNotEmpty
                                    ? s.titleAr
                                    : s.titleEn,
                              );
                              final label = picked == null
                                  ? slotTitle
                                  : _labelForSlot(locale, s, picked);
                              return _SlotChip(
                                label: label,
                                title: slotTitle,
                                selected: index == safeIndex,
                                onTap: () => setState(() => _slotIndex = index),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _TemplateMenu(
                        templates: catalogTemplates,
                        selectedId: activeTemplate.id,
                        mannequinId: editor.mannequinId,
                        buildStyleMode: editor.buildStyleMode,
                      ),
                      IconButton(
                        tooltip: localizedFromLocale(
                          locale,
                          AppStrings.editorBuildReset,
                          AppStrings.editorBuildResetAr,
                        ),
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
                    localizedLabel(
                      locale,
                      en: slot.titleEn,
                      ar: slot.titleAr.trim().isNotEmpty
                          ? slot.titleAr
                          : slot.titleEn,
                    ),
                    style: AppTextStyles.labelGold.copyWith(fontSize: 11),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: _OptionStrip(
                    locale: locale,
                    template: activeTemplate,
                    primaryColour: editor.primaryColour,
                    accentColour: editor.accentColour,
                    selections: editor.configuratorSelections,
                    slot: slot,
                    selectedOptionId: selectedOptionId,
                    onPick: (optionId) =>
                        ref.read(editorProvider.notifier).setConfiguratorOption(
                              template: activeTemplate,
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
                      localizedLabel(
                        locale,
                        en: selectedOption.labelEn,
                        ar: selectedOption.labelAr.trim().isNotEmpty
                            ? selectedOption.labelAr
                            : selectedOption.labelEn,
                      ),
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

  String _labelForSlot(Locale locale, ConfiguratorSlot slot, String optionId) {
    for (final o in slot.options) {
      if (o.id == optionId) {
        final label = localizedLabel(
          locale,
          en: o.labelEn,
          ar: o.labelAr.trim().isNotEmpty ? o.labelAr : o.labelEn,
        );
        final short = label.split(' ').first;
        return short.length > 10 ? '${short.substring(0, 9)}…' : short;
      }
    }
    return localizedLabel(
      locale,
      en: slot.titleEn,
      ar: slot.titleAr.trim().isNotEmpty ? slot.titleAr : slot.titleEn,
    );
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
    required this.mannequinId,
    required this.buildStyleMode,
  });

  final List<ConfiguratorTemplate> templates;
  final String selectedId;
  final String mannequinId;
  final EditorBuildStyleMode buildStyleMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EditorStyleDropdown(
      templates: templates,
      mannequinId: mannequinId,
      selectedTemplateId: selectedId,
      buildStyleMode: buildStyleMode,
      dense: true,
      onReset: () {
        ref.read(editorProvider.notifier).resetConfiguratorBuild(templates);
      },
    );
  }
}

/// Vertically scrollable grid of compact square configurator thumbs.
class _OptionStrip extends StatelessWidget {
  const _OptionStrip({
    required this.locale,
    required this.template,
    required this.primaryColour,
    required this.accentColour,
    required this.selections,
    required this.slot,
    required this.selectedOptionId,
    required this.onPick,
  });

  final Locale locale;
  final ConfiguratorTemplate template;
  final Color primaryColour;
  final Color accentColour;
  final ConfiguratorSelections selections;
  final ConfiguratorSlot slot;
  final String? selectedOptionId;
  final ValueChanged<String> onPick;

  static const double _spacing = 8;

  @override
  Widget build(BuildContext context) {
    const thumbW = EditorCompactThumbCard.thumbSize;
    const thumbH = EditorCompactThumbCard.stripHeight;
    final options = filteredOptionsForSlot(
      template: template,
      selections: selections,
      slot: slot,
    );

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
          itemCount: options.length,
          itemBuilder: (context, index) {
            final opt = options[index];
            final selected = selectedOptionId == opt.id;
            return EditorCompactThumbCard(
              label: localizedLabel(
                locale,
                en: opt.labelEn,
                ar: opt.labelAr.trim().isNotEmpty ? opt.labelAr : opt.labelEn,
              ),
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
