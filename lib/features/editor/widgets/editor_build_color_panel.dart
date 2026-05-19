import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/shared/widgets/full_spectrum_color_picker.dart';

/// Preset swatches for AI refined look (not applied to build layer PNGs).
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
        Text(
          AppStrings.editorBuildColorAiHint,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
        ),
        const SizedBox(height: AppSpacing.md),
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
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final c in kEditorBuildColorPresets)
              _Swatch(
                color: c,
                selected: selected.toARGB32() == c.toARGB32(),
                onTap: () => onPick(c),
              ),
            _CustomSwatch(
              selected: !kEditorBuildColorPresets.any(
                (c) => c.toARGB32() == selected.toARGB32(),
              ),
              onTap: () async {
                final picked = await showFullSpectrumColorPicker(
                  context,
                  initialColor: selected,
                  title: title,
                );
                if (picked != null) onPick(picked);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _CustomSwatch extends StatelessWidget {
  const _CustomSwatch({required this.selected, required this.onTap});

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
            borderRadius: BorderRadius.circular(AppRadius.sm),
            gradient: const SweepGradient(
              colors: [
                Color(0xFFFF0000),
                Color(0xFFFFFF00),
                Color(0xFF00FF00),
                Color(0xFF00FFFF),
                Color(0xFF0000FF),
                Color(0xFFFF00FF),
                Color(0xFFFF0000),
              ],
            ),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.borderSubtle,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: const Icon(Icons.tune, size: 18, color: Colors.white),
        ),
      ),
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
