import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Single-language label from English + Arabic copies (locale from settings).
class ArabicEnglishLabel extends ConsumerWidget {
  /// Creates a locale-aware label.
  const ArabicEnglishLabel({
    required this.arabicText,
    required this.englishText,
    super.key,
  });

  /// Arabic copy.
  final String arabicText;

  /// English copy.
  final String englishText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final isAr = locale.languageCode == 'ar';
    final text = localizedFromLocale(locale, englishText, arabicText);
    if (isAr) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Text(text, style: AppTextStyles.arabicLabel),
      );
    }
    return Text(text, style: AppTextStyles.labelGold);
  }
}
