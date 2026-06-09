import 'dart:ui' show Locale;

import 'package:lolipants/core/l10n/app_localization.dart';

/// Picks [ar] or [en] for CMS/API rows with bilingual labels.
String localizedLabel(
  Locale locale, {
  required String en,
  required String ar,
}) {
  return localizedFromLocale(locale, en, ar);
}
