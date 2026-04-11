import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Visual variants for [LolipantsButton].
enum LolipantsButtonVariant {
  /// Gold fill, ink label.
  primary,

  /// Gold outline, gold label.
  secondary,

  /// Ruby outline, ruby label.
  destructive,
}

/// Primary, secondary, and destructive buttons with a shared layout.
class LolipantsButton extends StatelessWidget {
  /// Creates a Lolipants-styled button.
  const LolipantsButton({
    required this.label,
    required this.onPressed,
    this.variant = LolipantsButtonVariant.primary,
    this.loading = false,
    this.fullWidth = true,
    super.key,
  });

  /// Visible label (caller supplies bilingual copy as needed).
  final String label;

  /// Tap handler; disabled when [loading] is true.
  final VoidCallback? onPressed;

  /// Surface and border styling.
  final LolipantsButtonVariant variant;

  /// When true, shows a gold progress indicator instead of the label.
  final bool loading;

  /// When true, stretches to the maximum horizontal width.
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading ? null : onPressed;

    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold,
            ),
          )
        : Text(
            label,
            style: AppTextStyles.titleMedium.copyWith(color: _foregroundColor),
          );

    final buttonStyle = _buttonStyle(context);

    final padded = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Center(child: child),
    );

    final Widget materialButton;
    switch (variant) {
      case LolipantsButtonVariant.primary:
        materialButton = FilledButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: padded,
        );
      case LolipantsButtonVariant.secondary:
      case LolipantsButtonVariant.destructive:
        materialButton = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: buttonStyle,
          child: padded,
        );
    }

    if (!fullWidth) {
      return materialButton;
    }

    return SizedBox(
      width: double.infinity,
      child: materialButton,
    );
  }

  Color get _foregroundColor {
    return switch (variant) {
      LolipantsButtonVariant.primary => AppColors.ink,
      LolipantsButtonVariant.secondary => AppColors.gold,
      LolipantsButtonVariant.destructive => AppColors.rubyLight,
    };
  }

  ButtonStyle _buttonStyle(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return switch (variant) {
      LolipantsButtonVariant.primary => FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.ink.withValues(alpha: 0.5),
          shape: shape,
          elevation: 0,
          splashFactory: NoSplash.splashFactory,
        ),
      LolipantsButtonVariant.secondary => OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold, width: 1.5),
          shape: shape,
          splashFactory: NoSplash.splashFactory,
        ),
      LolipantsButtonVariant.destructive => OutlinedButton.styleFrom(
          foregroundColor: AppColors.rubyLight,
          side: const BorderSide(color: AppColors.rubyLight, width: 1.5),
          shape: shape,
          splashFactory: NoSplash.splashFactory,
        ),
    };
  }
}
