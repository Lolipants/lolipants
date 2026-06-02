import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Locale-aware single-line caption under a FAB (settings language).
class FabLocaleCaption extends ConsumerWidget {
  /// Creates a caption from English + Arabic copies.
  const FabLocaleCaption({
    required this.labelEn,
    required this.labelAr,
    super.key,
    this.maxWidth = 96,
  });

  /// English copy.
  final String labelEn;

  /// Arabic copy.
  final String labelAr;

  /// Max width so long labels wrap instead of overflowing the screen edge.
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final isAr = locale.languageCode == 'ar';
    final text = localizedFromLocale(locale, labelEn, labelAr);
    final style = isAr
        ? AppTextStyles.arabicLabel.copyWith(fontSize: 9, height: 1.15)
        : AppTextStyles.labelGold.copyWith(
            fontSize: 10,
            letterSpacing: 0,
            height: 1.1,
          );

    final child = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        text,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );

    if (isAr) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      );
    }
    return child;
  }
}

/// Circular [FloatingActionButton] with a locale-aware caption underneath.
class LabeledFloatingActionButton extends ConsumerWidget {
  /// Creates a labeled FAB column.
  const LabeledFloatingActionButton({
    required this.onPressed,
    required this.labelEn,
    required this.labelAr,
    required this.icon,
    required this.heroTag,
    super.key,
    this.backgroundColor = AppColors.gold,
    this.foregroundColor = AppColors.ink,
    this.captionMaxWidth = 96,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  /// Tap handler.
  final VoidCallback? onPressed;

  /// English caption.
  final String labelEn;

  /// Arabic caption.
  final String labelAr;

  /// FAB icon.
  final IconData icon;

  /// Hero tag for route transitions.
  final Object heroTag;

  /// FAB fill color.
  final Color backgroundColor;

  /// FAB icon color.
  final Color foregroundColor;

  /// Caption max width.
  final double captionMaxWidth;

  /// Column alignment (use [CrossAxisAlignment.end] in end-aligned FAB stacks).
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final semanticsLabel = localizedFromLocale(locale, labelEn, labelAr);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Semantics(
          label: semanticsLabel,
          button: true,
          child: FloatingActionButton(
            heroTag: heroTag,
            elevation: 2,
            focusElevation: 4,
            hoverElevation: 4,
            highlightElevation: 6,
            onPressed: onPressed,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            child: Icon(icon),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        FabLocaleCaption(
          labelEn: labelEn,
          labelAr: labelAr,
          maxWidth: captionMaxWidth,
        ),
      ],
    );
  }
}
