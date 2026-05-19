import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/shared/widgets/full_spectrum_color_picker.dart';

/// Right-side quick colour swatches for editor.
class ColourStrip extends StatelessWidget {
  const ColourStrip({
    required this.selectedColour,
    required this.onSelected,
    this.embedded = false,
    super.key,
  });

  final Color selectedColour;
  final ValueChanged<Color> onSelected;

  /// When true, omit outer frame (use inside a shared panel).
  final bool embedded;

  static const _swatches = <Color>[
    Color(0xFF162F28),
    AppColors.gold,
    Color(0xFF1A1040),
    Color(0xFF6B1A1A),
    AppColors.sand,
    AppColors.ink,
  ];

  @override
  Widget build(BuildContext context) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final swatch in _swatches)
          _Swatch(
            color: swatch,
            isSelected: swatch.value == selectedColour.value,
            onTap: () => onSelected(swatch),
          ),
        _Swatch(
          color: AppColors.smoke,
          isSelected: false,
          child: const Icon(Icons.add, size: 12, color: AppColors.gold),
          onTap: () => _openPicker(context),
        ),
      ],
    );
    if (embedded) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: column,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: column,
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showFullSpectrumColorPicker(
      context,
      initialColor: selectedColour,
    );
    if (picked != null) onSelected(picked);
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.child,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: isSelected ? AppColors.gold : AppColors.borderDefault,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
