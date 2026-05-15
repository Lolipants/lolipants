import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

/// Preset swatches for build-mode garment tinting.
const List<Color> kEditorBuildColorPresets = [
  Color(0xFF141414),
  Color(0xFF162F40),
  Color(0xFF1B4A42),
  Color(0xFF1F4D3A),
  Color(0xFF3B2A22),
  Color(0xFF5C1F3A),
  Color(0xFF4A2A4F),
  Color(0xFFE8DCC8),
  Color(0xFFF5F0E6),
  Color(0xFFD8D4CE),
  Color(0xFFC9A14A),
  Color(0xFF6B6B6B),
];

/// Primary and accent colour pickers for the Build tab.
class EditorBuildColorPanel extends ConsumerWidget {
  const EditorBuildColorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      children: [
        _ColorSection(
          title: AppStrings.editorBuildColorPrimary,
          selected: editor.primaryColour,
          onPick: notifier.setPrimaryColour,
        ),
        const SizedBox(height: AppSpacing.lg),
        _ColorSection(
          title: AppStrings.editorBuildColorAccent,
          selected: editor.accentColour,
          onPick: notifier.setAccentColour,
        ),
      ],
    );
  }
}

class _ColorSection extends StatelessWidget {
  const _ColorSection({
    required this.title,
    required this.selected,
    required this.onPick,
  });

  final String title;
  final Color selected;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.sand)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final c in kEditorBuildColorPresets)
              _Swatch(
                color: c,
                selected: selected.value == c.value,
                onTap: () => onPick(c),
              ),
          ],
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.borderSubtle,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
