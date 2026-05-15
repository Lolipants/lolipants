import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/configurator_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/configurator_option_image.dart';
import 'package:lolipants/features/editor/widgets/editor_build_color_panel.dart';

/// Modular “Design yourself” bottom panel: template → slot tabs → options.
class EditorBuildPanel extends ConsumerStatefulWidget {
  const EditorBuildPanel({super.key});

  @override
  ConsumerState<EditorBuildPanel> createState() => _EditorBuildPanelState();
}

class _EditorBuildPanelState extends ConsumerState<EditorBuildPanel>
    with TickerProviderStateMixin {
  TabController? _tabController;
  String? _tabTemplateId;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _ensureTabController(int length, String templateId) {
    if (_tabController != null &&
        _tabController!.length == length &&
        _tabTemplateId == templateId) {
      return;
    }
    _tabController?.dispose();
    _tabTemplateId = templateId;
    _tabController = TabController(length: length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorProvider);
    final catalogAsync = ref.watch(configuratorCatalogProvider);
    final panelHeight = (MediaQuery.sizeOf(context).height * 0.34)
        .clamp(260.0, 340.0);

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
            final selectedId = editor.configuratorTemplateId.trim();
            ConfiguratorTemplate? template;
            if (selectedId.isNotEmpty) {
              for (final t in templates) {
                if (t.id == selectedId) {
                  template = t;
                  break;
                }
              }
            }
            final slots = template?.slots ?? const <ConfiguratorSlot>[];
            final tabCount = slots.length + 1;
            _ensureTabController(
              tabCount,
              selectedId.isEmpty ? '__none__' : selectedId,
            );
            final tabs = _tabController!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.editorTabBuild,
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.sand),
                        ),
                      ),
                      DropdownButton<String?>(
                        value: template?.id,
                        hint: Text(
                          AppStrings.editorBuildPickTemplate,
                          style: AppTextStyles.bodySmall,
                        ),
                        underline: const SizedBox.shrink(),
                        dropdownColor: AppColors.stone,
                        items: [
                          for (final t in templates)
                            DropdownMenuItem(
                              value: t.id,
                              child: Text(
                                '${t.nameEn} · ${t.nameAr}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                        ],
                        onChanged: (id) {
                          if (id == null) return;
                          ref
                              .read(editorProvider.notifier)
                              .setConfiguratorTemplate(id, templates);
                        },
                      ),
                    ],
                  ),
                ),
                if (template == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      0,
                    ),
                    child: Text(
                      AppStrings.editorBuildResetHint,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.fog,
                      ),
                    ),
                  ),
                TabBar(
                  controller: tabs,
                  isScrollable: true,
                  labelColor: AppColors.gold,
                  unselectedLabelColor: AppColors.fog,
                  indicatorColor: AppColors.gold,
                  labelStyle: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  tabs: [
                    for (final slot in slots)
                      Tab(text: slot.titleEn),
                    const Tab(text: AppStrings.editorBuildTabColor),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabs,
                    children: [
                      if (template != null)
                        for (final slot in slots)
                          _OptionGrid(
                            slot: slot,
                            selectedOptionId:
                                editor.configuratorSelections[slot.id],
                            onPick: (optionId) => ref
                                .read(editorProvider.notifier)
                                .setConfiguratorOption(
                                  template: template!,
                                  slotId: slot.id,
                                  optionId: optionId,
                                ),
                          ),
                      const EditorBuildColorPanel(),
                    ],
                  ),
                ),
                if (editor.configuratorSummary.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      0,
                    ),
                    child: Text(
                      editor.configuratorSummary,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.fog,
                        height: 1.35,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(editorProvider.notifier)
                        .resetConfiguratorBuild(),
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text(AppStrings.editorBuildReset),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.sand,
                      side: const BorderSide(color: AppColors.borderStrong),
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
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.slot,
    required this.selectedOptionId,
    required this.onPick,
  });

  final ConfiguratorSlot slot;
  final String? selectedOptionId;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.85,
      ),
      itemCount: slot.options.length,
      itemBuilder: (context, index) {
        final opt = slot.options[index];
        final selected = selectedOptionId == opt.id;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onPick(opt.id),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.smoke,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: selected ? AppColors.gold : AppColors.borderSubtle,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ConfiguratorOptionImage(option: opt),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                    child: Text(
                      opt.labelEn,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: selected ? AppColors.gold : AppColors.fog,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
