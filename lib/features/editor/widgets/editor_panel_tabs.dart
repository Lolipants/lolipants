import 'package:flutter/material.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

/// Switches bottom editor panel between Designs catalogue and Build configurator.
class EditorPanelTabs extends StatelessWidget {
  const EditorPanelTabs({
    required this.activeTab,
    required this.onTabChanged,
    super.key,
  });

  final EditorTab activeTab;
  final ValueChanged<EditorTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = <(EditorTab, String)>[
      (EditorTab.designs, AppStrings.editorTabDesigns),
      if (kFeatureConfiguratorBuild) (EditorTab.build, AppStrings.editorTabBuild),
      if (kFeatureWeddingTab) (EditorTab.wedding, AppStrings.editorTabWedding),
    ];
    return Material(
      color: AppColors.stone,
      child: Row(
        children: [
          for (final entry in tabs) ...[
            Expanded(
              child: _TabButton(
                label: entry.$2,
                selected: activeTab == entry.$1,
                onTap: () => onTabChanged(entry.$1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.gold : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelGold.copyWith(
            color: selected ? AppColors.gold : AppColors.fog,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
