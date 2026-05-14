import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

/// Vertical editor tool rail.
class ToolRail extends StatelessWidget {
  const ToolRail({
    required this.activeTool,
    required this.onToolSelected,
    required this.onSizingTap,
    this.embedded = false,
    super.key,
  });

  final EditorTool activeTool;
  final ValueChanged<EditorTool> onToolSelected;
  final VoidCallback onSizingTap;

  /// When true, omit outer frame (use inside a shared panel).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolButton(
          icon: Icons.palette_outlined,
          active: activeTool == EditorTool.colour,
          onTap: () => onToolSelected(EditorTool.colour),
        ),
        _ToolButton(
          icon: Icons.text_fields,
          active: activeTool == EditorTool.text,
          onTap: () => onToolSelected(EditorTool.text),
        ),
        _ToolButton(
          icon: Icons.image_outlined,
          active: activeTool == EditorTool.image,
          onTap: () => onToolSelected(EditorTool.image),
        ),
        _ToolButton(
          icon: Icons.straighten,
          active: activeTool == EditorTool.sizing,
          onTap: onSizingTap,
        ),
      ],
    );
    if (embedded) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: column,
      );
    }
    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: column,
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? AppColors.borderDefault : AppColors.smoke,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(icon,
              color: active ? AppColors.gold : AppColors.sand, size: 16),
        ),
      ),
    );
  }
}
