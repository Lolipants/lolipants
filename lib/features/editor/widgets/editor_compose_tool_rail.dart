import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';

/// Vertical compose tools on the mannequin hero (palette, text, image).
class EditorComposeToolRail extends StatelessWidget {
  const EditorComposeToolRail({
    required this.onPalette,
    required this.onAddText,
    required this.onAddImage,
    super.key,
  });

  final VoidCallback onPalette;
  final VoidCallback onAddText;
  final VoidCallback onAddImage;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      top: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolButton(
            tooltip: 'Colour & fabric',
            icon: Icons.palette_outlined,
            onPressed: onPalette,
          ),
          const SizedBox(height: AppSpacing.xs),
          _ToolButton(
            tooltip: AppStrings.editorTabText,
            icon: Icons.text_fields,
            onPressed: onAddText,
          ),
          const SizedBox(height: AppSpacing.xs),
          _ToolButton(
            tooltip: AppStrings.editorAddImage,
            icon: Icons.add_photo_alternate_outlined,
            onPressed: onAddImage,
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.stone.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: AppColors.gold),
          ),
        ),
      ),
    );
  }
}
