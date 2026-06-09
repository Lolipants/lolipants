import 'dart:ui' show Locale;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Picks [ar] when the app locale is Arabic, otherwise [en].
String localizedFromLocale(Locale locale, String en, String ar) {
  return locale.languageCode == 'ar' ? ar : en;
}

/// Picks [ar] when [ref] settings locale is Arabic, otherwise [en].
String localized(WidgetRef ref, String en, String ar) {
  final locale = ref.watch(settingsLocaleProvider);
  return localizedFromLocale(locale, en, ar);
}

/// Reads settings locale from [context] via [ProviderScope].
String localizedFromContext(BuildContext context, String en, String ar) {
  final container = ProviderScope.containerOf(context, listen: true);
  final locale = container.read(settingsLocaleProvider);
  return localizedFromLocale(locale, en, ar);
}

/// Splits `"English / عربي"` or `"Featured · مميز"` and picks by locale.
String pickEmbeddedBilingual(Locale locale, String combined) {
  for (final sep in [' / ', ' · ']) {
    final i = combined.indexOf(sep);
    if (i >= 0) {
      return localizedFromLocale(
        locale,
        combined.substring(0, i).trim(),
        combined.substring(i + sep.length).trim(),
      );
    }
  }
  return combined;
}

/// Bilingual label (legacy); prefer [localizedFromLocale] for single-language UI.
String bilingualLabel(String en, String ar) => '$en / $ar';

/// Picks one language from a combined `English / عربي` [AppStrings] value.
String pickSlashFromContext(BuildContext context, String combined) {
  final container = ProviderScope.containerOf(context, listen: true);
  final locale = container.read(settingsLocaleProvider);
  return AppStrings.pickEmbedded(locale, combined);
}

/// Same as [pickSlashFromContext] using settings locale from [ref].
String pickSlash(WidgetRef ref, String combined) {
  final locale = ref.watch(settingsLocaleProvider);
  return AppStrings.pickEmbedded(locale, combined);
}

/// Locale-aware medium date, e.g. Jan 5, 2026 / ٥ يناير ٢٠٢٦.
DateFormat dateFormatYMMMd(Locale locale) =>
    DateFormat.yMMMd(locale.languageCode);

/// Locale-aware short month + day.
DateFormat dateFormatMMMd(Locale locale) =>
    DateFormat.MMMd(locale.languageCode);

/// Locale-aware number formatter.
NumberFormat numberFormatFor(Locale locale) =>
    NumberFormat.decimalPattern(locale.languageCode);
