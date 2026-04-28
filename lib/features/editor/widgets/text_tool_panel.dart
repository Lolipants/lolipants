import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Text editing controls shown in the editor bottom panel.
class TextToolPanel extends StatefulWidget {
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
  State<TextToolPanel> createState() => _TextToolPanelState();
}

class _TextToolPanelState extends State<TextToolPanel> {
  final _textController = TextEditingController();

  static const _fonts = <String>[
    'Poppins',
    'NotoNaskhArabic',
    'PlayfairDisplay',
    'RobotoMono',
    'DancingScript',
    'Amiri',
  ];

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
    final selected = widget.selectedLayer;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Type your text / اكتب نصك',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: () {
                widget.onAddLayer(_textController.text);
                _textController.clear();
              },
              child: const Text('Add to design'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.layers.isNotEmpty) ...[
          Text('Layers', style: AppTextStyles.titleSmall),
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
        Text('Font', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final font in _fonts)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(font, style: TextStyle(fontFamily: font)),
                    selected: selected?.fontFamily == font,
                    onSelected: selected == null
                        ? null
                        : (_) => widget.onUpdateSelected(fontFamily: font),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Size: ${selected?.fontSize.toStringAsFixed(0) ?? '-'}'),
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
        Text('Rotation ${(selected?.rotation ?? 0).toStringAsFixed(2)} rad'),
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
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final colour in _colours)
              GestureDetector(
                onTap: selected == null
                    ? null
                    : () => widget.onUpdateSelected(colour: colour),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colour,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Drag the text on the garment to reposition / اسحب النص على الملبس لتغيير موضعه',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        if (selected != null)
          LolipantsButton(
            label: 'Remove text / حذف النص',
            variant: LolipantsButtonVariant.destructive,
            onPressed: widget.onRemoveSelected,
          ),
      ],
    );
  }
}
