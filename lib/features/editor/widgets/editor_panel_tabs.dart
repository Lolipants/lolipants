import 'package:flutter/material.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

/// Design / Wedding switcher inside the unified bottom panel.
class EditorPanelTabs extends StatelessWidget {
  const EditorPanelTabs({
    required this.activeTab,
    required this.onTabChanged,
    this.weddingTabEnabled = true,
    super.key,
  });

  final EditorTab activeTab;
  final ValueChanged<EditorTab> onTabChanged;
  final bool weddingTabEnabled;

  bool get _designSelected =>
      activeTab == EditorTab.build || activeTab == EditorTab.designs;

  @override
  Widget build(BuildContext context) {
    final tabs = <(EditorTab, String)>[
      if (kFeatureConfiguratorBuild) (EditorTab.build, 'Design'),
      if (kFeatureWeddingTab && weddingTabEnabled)
        (EditorTab.wedding, AppStrings.editorTabWedding),
    ];
    if (tabs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.smoke,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            for (final entry in tabs)
              Expanded(
                child: _TabButton(
                  label: entry.$2,
                  selected: entry.$1 == EditorTab.wedding
                      ? activeTab == EditorTab.wedding
                      : _designSelected,
                  enabled: entry.$1 != EditorTab.wedding || weddingTabEnabled,
                  onTap: () => onTabChanged(entry.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: !enabled
                  ? AppColors.fog.withValues(alpha: 0.35)
                  : selected
                      ? AppColors.gold
                      : AppColors.fog,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
