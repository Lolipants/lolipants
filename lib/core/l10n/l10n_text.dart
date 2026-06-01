import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Single-language [Text] from English + Arabic copies (or embedded `EN / AR`).
class L10nText extends ConsumerWidget {
  /// Creates localized text.
  const L10nText(
    this.en, {
    this.ar,
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.rtlWhenArabic = true,
  });

  /// English copy, or a combined `English / عربي` string when [ar] is null.
  final String en;

  /// Arabic copy; when null, [en] may contain ` / ` or ` · ` separators.
  final String? ar;

  /// Optional style.
  final TextStyle? style;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Max lines.
  final int? maxLines;

  /// Overflow behavior.
  final TextOverflow? overflow;

  /// Wrap in RTL [Directionality] when showing Arabic.
  final bool rtlWhenArabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final text = ar != null
        ? localizedFromLocale(locale, en, ar!)
        : pickEmbeddedBilingual(locale, en);
    final child = Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
    if (rtlWhenArabic && locale.languageCode == 'ar') {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      );
    }
    return child;
  }
}
