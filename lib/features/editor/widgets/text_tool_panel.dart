import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/editor/data/editor_text_fonts.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/full_spectrum_color_picker.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Text editing controls shown in the editor bottom panel.
class TextToolPanel extends ConsumerStatefulWidget {
  const TextToolPanel({
    required this.layers,
    required this.selectedLayer,
    required this.onAddLayer,
    required this.onSelectLayer,
    required this.onUpdateSelected,
    required this.onRemoveSelected,
    super.key,
  });

  final List<EditorTextLayer> layers;
  final EditorTextLayer? selectedLayer;
  final ValueChanged<String> onAddLayer;
  final ValueChanged<String> onSelectLayer;
  final void Function({
    String? fontFamily,
    double? fontSize,
    Color? colour,
    double? rotation,
  }) onUpdateSelected;
  final VoidCallback onRemoveSelected;

  @override
  ConsumerState<TextToolPanel> createState() => _TextToolPanelState();
}

class _TextToolPanelState extends ConsumerState<TextToolPanel> {
  final _textController = TextEditingController();

  static const _colours = <Color>[
    AppColors.sand,
    AppColors.gold,
    AppColors.tealLight,
    AppColors.rubyLight,
    Colors.white,
    Colors.black,
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsLocaleProvider);
    final selected = widget.selectedLayer;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: localizedFromLocale(
                    locale,
                    AppStrings.editorTextTypeHint,
                    AppStrings.editorTextTypeHintAr,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: () {
                widget.onAddLayer(_textController.text);
                _textController.clear();
              },
              child: Text(
                localizedFromLocale(
                  locale,
                  AppStrings.editorTextAddToDesign,
                  AppStrings.editorTextAddToDesignAr,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.layers.isNotEmpty) ...[
          Text(
            localizedFromLocale(
              locale,
              AppStrings.editorTextLayers,
              AppStrings.editorTextLayersAr,
            ),
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final layer in widget.layers)
                ChoiceChip(
                  label: Text(layer.text, overflow: TextOverflow.ellipsis),
                  selected: selected?.id == layer.id,
                  onSelected: (_) => widget.onSelectLayer(layer.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          localizedFromLocale(
            locale,
            AppStrings.editorTextFont,
            AppStrings.editorTextFontAr,
          ),
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kCasualEditorTextFonts.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final font = kCasualEditorTextFonts[index];
              final isSelected = editorTextFontById(selected?.fontFamily)?.id ==
                  font.id;
              final preview = font.build(
                fontSize: 16,
                color: isSelected ? AppColors.ink : AppColors.sand,
              );
              return ChoiceChip(
                label: Text(font.previewSample, style: preview),
                showCheckmark: false,
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                selected: isSelected,
                onSelected: selected == null
                    ? null
                    : (_) => widget.onUpdateSelected(fontFamily: font.id),
              );
            },
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            editorTextFontById(selected.fontFamily)?.label ?? selected.fontFamily,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          '${localizedFromLocale(locale, AppStrings.editorTextSizePrefix, AppStrings.editorTextSizePrefixAr)}: ${selected?.fontSize.toStringAsFixed(0) ?? '-'}',
        ),
        Slider(
          value: (selected?.fontSize ?? 20).clamp(12, 48),
          min: 12,
          max: 48,
          divisions: 36,
          onChanged: selected == null
              ? null
              : (value) => widget.onUpdateSelected(fontSize: value),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${localizedFromLocale(locale, AppStrings.editorTextRotationPrefix, AppStrings.editorTextRotationPrefixAr)} ${(selected?.rotation ?? 0).toStringAsFixed(2)} rad',
        ),
        Slider(
          value: (selected?.rotation ?? 0).clamp(-3.14, 3.14),
          min: -3.14,
          max: 3.14,
          divisions: 64,
          onChanged: selected == null
              ? null
              : (value) => widget.onUpdateSelected(rotation: value),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          localizedFromLocale(
            locale,
            AppStrings.editorTextColour,
            AppStrings.editorTextColourAr,
          ),
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final colour in _colours)
              GestureDetector(
                onTap: selected == null
                    ? null
                    : () => widget.onUpdateSelected(colour: colour),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colour,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected?.colour.toARGB32() == colour.toARGB32()
                          ? AppColors.gold
                          : AppColors.borderDefault,
                      width: selected?.colour.toARGB32() == colour.toARGB32()
                          ? 2
                          : 1,
                    ),
                  ),
                ),
              ),
            if (selected != null)
              CustomColourSwatch(
                size: 28,
                selected: !_colours.any(
                  (c) => c.toARGB32() == selected.colour.toARGB32(),
                ),
                onColourPicked: (c) => widget.onUpdateSelected(colour: c),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          localizedFromLocale(
            locale,
            AppStrings.editorTextDragHint,
            AppStrings.editorTextDragHintAr,
          ),
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        if (selected != null)
          LolipantsButton(
            label: localizedFromLocale(
              locale,
              AppStrings.editorTextRemove,
              AppStrings.editorTextRemoveAr,
            ),
            variant: LolipantsButtonVariant.destructive,
            onPressed: widget.onRemoveSelected,
          ),
      ],
    );
  }
}
