import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// A single pill chip used in the editor panel header (slots / filters).
class EditorHeaderChipData {
  const EditorHeaderChipData({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
}

/// Shared header layout for the editor bottom panels: a leading control
/// (the style dropdown) followed by a horizontally scrollable row of pill
/// chips. Used by both the catalogue and configurator panels so their headers
/// look and behave identically.
class EditorPanelHeader extends StatelessWidget {
  const EditorPanelHeader({
    required this.leading,
    required this.chips,
    this.embedded = false,
    super.key,
  });

  final Widget leading;
  final List<EditorHeaderChipData> chips;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        embedded ? AppSpacing.xs : AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: SizedBox(
        height: 32,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final chip = chips[index];
                  return EditorHeaderChip(
                    label: chip.label,
                    selected: chip.selected,
                    onTap: chip.onTap,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill chip rendered inside [EditorPanelHeader].
class EditorHeaderChip extends StatelessWidget {
  const EditorHeaderChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.14)
                  : AppColors.smoke,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? AppColors.gold : AppColors.borderSubtle,
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
      ),
    );
  }
}
