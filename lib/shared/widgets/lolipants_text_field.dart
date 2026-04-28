import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Text field matching the Lolipants smoke surface and gold focus ring.
class LolipantsTextField extends StatefulWidget {
  /// Creates a styled text field.
  const LolipantsTextField({
    required this.label,
    this.controller,
    this.obscureText = false,
    this.obscureToggle = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    super.key,
  });

  /// Floating label text (English or combined copy from caller).
  final String label;

  /// Optional editing controller.
  final TextEditingController? controller;

  /// When true, masks input (password).
  final bool obscureText;

  /// When true with [obscureText], shows an eye toggle suffix.
  final bool obscureToggle;

  /// Keyboard type hint.
  final TextInputType? keyboardType;

  /// IME action button.
  final TextInputAction? textInputAction;

  /// Emits on every change.
  final ValueChanged<String>? onChanged;

  /// Inline validation message rendered below the field.
  final String? errorText;

  /// Optional leading icon inside the field.
  final Widget? prefixIcon;

  /// Optional trailing icon (ignored when [obscureToggle] reserves suffix).
  final Widget? suffixIcon;

  /// Optional formatters (e.g. digits only).
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<LolipantsTextField> createState() => _LolipantsTextFieldState();
}

class _LolipantsTextFieldState extends State<LolipantsTextField> {
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant LolipantsTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _hidden = widget.obscureText;
    }
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: 1.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final borderColor =
        hasError ? AppColors.rubyLight : AppColors.borderSubtle;

    final suffix = widget.obscureToggle
        ? IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onPressed: () => setState(() => _hidden = !_hidden),
            icon: Icon(
              _hidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.dust,
            ),
          )
        : widget.suffixIcon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: widget.label,
          textField: true,
          child: TextField(
            controller: widget.controller,
            obscureText: widget.obscureToggle ? _hidden : widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            inputFormatters: widget.inputFormatters,
            style: AppTextStyles.bodyLarge,
            cursorColor: AppColors.gold,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.smoke,
              labelText: widget.label,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.dust,
              ),
              floatingLabelStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.dust,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: suffix,
              enabledBorder: _border(borderColor),
              focusedBorder: _border(
                hasError ? AppColors.rubyLight : AppColors.gold,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.errorText!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.rubyLight),
          ),
        ],
      ],
    );
  }
}
