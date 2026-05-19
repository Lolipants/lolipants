import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Opens a Photoshop-style picker: saturation/value field + hue slider + hex.
Future<Color?> showFullSpectrumColorPicker(
  BuildContext context, {
  required Color initialColor,
  String title = 'Choose colour',
  bool enableAlpha = false,
}) {
  return showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _FullSpectrumColorPickerSheet(
      initialColor: initialColor,
      title: title,
      enableAlpha: enableAlpha,
    ),
  );
}

String colorToHex(Color color, {bool withAlpha = false}) {
  final value = color.toARGB32();
  final hex = value.toRadixString(16).padLeft(8, '0');
  if (withAlpha) return '#${hex.toUpperCase()}';
  return '#${hex.substring(2).toUpperCase()}';
}

class _FullSpectrumColorPickerSheet extends StatefulWidget {
  const _FullSpectrumColorPickerSheet({
    required this.initialColor,
    required this.title,
    required this.enableAlpha,
  });

  final Color initialColor;
  final String title;
  final bool enableAlpha;

  @override
  State<_FullSpectrumColorPickerSheet> createState() =>
      _FullSpectrumColorPickerSheetState();
}

class _FullSpectrumColorPickerSheetState
    extends State<_FullSpectrumColorPickerSheet> {
  late Color _current;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _current = widget.initialColor;
    _hexController = TextEditingController(
      text: colorToHex(_current, withAlpha: widget.enableAlpha),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _onColorChanged(Color color) {
    setState(() => _current = color);
    final hex = colorToHex(color, withAlpha: widget.enableAlpha);
    if (_hexController.text.toUpperCase() != hex) {
      _hexController.text = hex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxWidth = MediaQuery.sizeOf(context).width;
    final pickerWidth = (maxWidth - AppSpacing.lg * 2).clamp(260.0, 360.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.stone,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          border: Border(top: BorderSide(color: AppColors.borderStrong)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.sand,
                        ),
                      ),
                    ),
                    _LiveSwatch(color: _current),
                  ],
                ),
              ),
              ColorPicker(
                pickerColor: _current,
                onColorChanged: _onColorChanged,
                colorPickerWidth: pickerWidth,
                pickerAreaHeightPercent: 0.72,
                enableAlpha: widget.enableAlpha,
                displayThumbColor: true,
                paletteType: PaletteType.hsvWithHue,
                labelTypes: const [ColorLabelType.rgb, ColorLabelType.hsv],
                pickerAreaBorderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.sm),
                ),
                hexInputController: _hexController,
                portraitOnly: true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Text(
                      'Hex',
                      style: AppTextStyles.labelGold.copyWith(fontSize: 10),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _hexController,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.sand,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.smoke,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                            borderSide: const BorderSide(
                              color: AppColors.borderSubtle,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        autocorrect: false,
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.dust,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: LolipantsButton(
                        label: 'Apply colour',
                        fullWidth: true,
                        onPressed: () => Navigator.of(context).pop(_current),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveSwatch extends StatelessWidget {
  const _LiveSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// Small “custom” swatch that opens [showFullSpectrumColorPicker].
class CustomColourSwatch extends StatelessWidget {
  const CustomColourSwatch({
    required this.onColourPicked,
    this.size = 36,
    this.selected = false,
    super.key,
  });

  final ValueChanged<Color> onColourPicked;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final picked = await showFullSpectrumColorPicker(
            context,
            initialColor: AppColors.gold,
          );
          if (picked != null) onColourPicked(picked);
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
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
              color: selected ? AppColors.gold : AppColors.borderDefault,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Icon(
            Icons.add,
            size: size * 0.45,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
      ),
    );
  }
}
