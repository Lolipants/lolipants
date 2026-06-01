import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// One [Text] line from English + Arabic copies (settings locale).
class LocaleBilingualText extends ConsumerWidget {
  /// Creates locale-aware text.
  const LocaleBilingualText({
    required this.en,
    required this.ar,
    super.key,
    this.enStyle,
    this.arStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// English copy.
  final String en;

  /// Arabic copy.
  final String ar;

  /// Style when locale is English.
  final TextStyle? enStyle;

  /// Style when locale is Arabic.
  final TextStyle? arStyle;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Max lines.
  final int? maxLines;

  /// Overflow.
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final isAr = locale.languageCode == 'ar';
    final text = localizedFromLocale(locale, en, ar);
    final style = isAr
        ? (arStyle ?? AppTextStyles.arabicBody)
        : (enStyle ?? AppTextStyles.bodyMedium);
    final child = Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
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
