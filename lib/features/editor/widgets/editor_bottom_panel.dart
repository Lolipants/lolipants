import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/ai_prompt_bar.dart';
import 'package:lolipants/features/editor/widgets/text_tool_panel.dart';

/// Bottom tab panel for the editor shell.
class EditorBottomPanel extends StatelessWidget {
  const EditorBottomPanel({
    required this.state,
    required this.onTabChanged,
    required this.onFabricSelected,
    required this.onQualitySelected,
    required this.onPatternSelected,
    required this.onEmbroiderySelected,
    required this.onAddTextLayer,
    required this.onSelectTextLayer,
    required this.onUpdateSelectedText,
    required this.onRemoveSelectedText,
    super.key,
  });

  final EditorState state;
  final ValueChanged<EditorTab> onTabChanged;
  final ValueChanged<String> onFabricSelected;
  final ValueChanged<String> onQualitySelected;
  final ValueChanged<String> onPatternSelected;
  final ValueChanged<String> onEmbroiderySelected;
  final ValueChanged<String> onAddTextLayer;
  final ValueChanged<String> onSelectTextLayer;
  final void Function({
    String? fontFamily,
    double? fontSize,
    Color? colour,
  }) onUpdateSelectedText;
  final VoidCallback onRemoveSelectedText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: const Border(top: BorderSide(color: AppColors.borderStrong)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          _TabRow(active: state.activeTab, onChanged: onTabChanged),
          const Divider(height: 1, color: AppColors.borderSubtle),
          Expanded(
            child: _PanelBody(
              state: state,
              onFabricSelected: onFabricSelected,
              onQualitySelected: onQualitySelected,
              onPatternSelected: onPatternSelected,
              onEmbroiderySelected: onEmbroiderySelected,
              onAddTextLayer: onAddTextLayer,
              onSelectTextLayer: onSelectTextLayer,
              onUpdateSelectedText: onUpdateSelectedText,
              onRemoveSelectedText: onRemoveSelectedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({required this.active, required this.onChanged});
  final EditorTab active;
  final ValueChanged<EditorTab> onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = <(EditorTab, String)>[
      (EditorTab.fabric, AppStrings.editorTabFabric),
      (EditorTab.pattern, AppStrings.editorTabPattern),
      (EditorTab.embroidery, AppStrings.editorTabEmbroidery),
      (EditorTab.text, AppStrings.editorTabText),
      (EditorTab.ai, AppStrings.editorTabAi),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs)
            InkWell(
              onTap: () => onChanged(tab.$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    Text(
                      tab.$2,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: active == tab.$1 ? AppColors.gold : AppColors.fog,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: 2,
                      color: active == tab.$1
                          ? AppColors.gold
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({
    required this.state,
    required this.onFabricSelected,
    required this.onQualitySelected,
    required this.onPatternSelected,
    required this.onEmbroiderySelected,
    required this.onAddTextLayer,
    required this.onSelectTextLayer,
    required this.onUpdateSelectedText,
    required this.onRemoveSelectedText,
  });

  final EditorState state;
  final ValueChanged<String> onFabricSelected;
  final ValueChanged<String> onQualitySelected;
  final ValueChanged<String> onPatternSelected;
  final ValueChanged<String> onEmbroiderySelected;
  final ValueChanged<String> onAddTextLayer;
  final ValueChanged<String> onSelectTextLayer;
  final void Function({
    String? fontFamily,
    double? fontSize,
    Color? colour,
  }) onUpdateSelectedText;
  final VoidCallback onRemoveSelectedText;

  @override
  Widget build(BuildContext context) {
    return switch (state.activeTab) {
      EditorTab.fabric => _FabricPanel(
          selectedFabric: state.selectedFabricId,
          availableFabrics: state.availableFabrics,
          quality: state.fabricQuality,
          onFabricSelected: onFabricSelected,
          onQualitySelected: onQualitySelected,
        ),
      EditorTab.pattern => _SelectionPanel(
          options: const ['geometric', 'stripe', 'plain', 'arabesque', 'floral', 'embroidered'],
          selected: state.selectedPatternId,
          onSelected: onPatternSelected,
        ),
      EditorTab.embroidery => _SelectionPanel(
          options: const ['motif_1', 'motif_2', 'motif_3', 'motif_4'],
          selected: state.selectedEmbroideryId,
          onSelected: onEmbroiderySelected,
        ),
      EditorTab.text => TextToolPanel(
          layers: state.textLayers,
          selectedLayer: _selectedLayer(state),
          onAddLayer: onAddTextLayer,
          onSelectLayer: onSelectTextLayer,
          onUpdateSelected: onUpdateSelectedText,
          onRemoveSelected: onRemoveSelectedText,
        ),
      EditorTab.ai => const AiPromptBar(embedInEditor: true),
    };
  }

  EditorTextLayer? _selectedLayer(EditorState state) {
    final id = state.selectedTextLayerId;
    if (id == null) return null;
    for (final layer in state.textLayers) {
      if (layer.id == id) return layer;
    }
    return null;
  }
}

class _FabricPanel extends StatelessWidget {
  const _FabricPanel({
    required this.selectedFabric,
    required this.availableFabrics,
    required this.quality,
    required this.onFabricSelected,
    required this.onQualitySelected,
  });

  final String selectedFabric;
  final List<String> availableFabrics;
  final String quality;
  final ValueChanged<String> onFabricSelected;
  final ValueChanged<String> onQualitySelected;

  @override
  Widget build(BuildContext context) {
    const qualities = <String>['standard', 'premium', 'suit_grade'];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final fabric in availableFabrics)
                ChoiceChip(
                  label: Text(fabric),
                  selected: selectedFabric == fabric,
                  onSelected: (_) => onFabricSelected(fabric),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final q in qualities)
                ChoiceChip(
                  label: Text(q.replaceAll('_', '-')),
                  selected: quality == q,
                  onSelected: (_) => onQualitySelected(q),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final item = options[index];
        final active = item == selected;
        return InkWell(
          onTap: () => onSelected(item),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.smoke,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: active ? AppColors.gold : AppColors.borderSubtle,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              item,
              style: AppTextStyles.bodySmall.copyWith(
                color: active ? AppColors.gold : AppColors.dust,
              ),
            ),
          ),
        );
      },
    );
  }
}
