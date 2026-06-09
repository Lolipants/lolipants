import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';

const String _latinFont = 'Poppins';
const String _arabicFont = 'NotoNaskhArabic';

/// Builds the global dark [ThemeData] for Lolipants.
ThemeData buildAppTheme({Locale? locale}) {
  final isAr = locale?.languageCode == 'ar';
  final base = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.blush,
      tertiary: AppColors.goldLight,
      surface: AppColors.stone,
      error: AppColors.rubyLight,
    ),
    cardColor: AppColors.ember,
    dividerColor: AppColors.borderSubtle,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    useMaterial3: true,
    fontFamily: isAr ? _arabicFont : _latinFont,
  );
  if (!isAr) return base;
  return base.copyWith(
    textTheme: _arabicTextTheme(base.textTheme),
    primaryTextTheme: _arabicTextTheme(base.primaryTextTheme),
  );
}

TextTheme _arabicTextTheme(TextTheme base) {
  TextStyle arabic(TextStyle? style) {
    if (style == null) {
      return const TextStyle(fontFamily: _arabicFont);
    }
    return style.copyWith(fontFamily: _arabicFont);
  }

  return TextTheme(
    displayLarge: arabic(base.displayLarge),
    displayMedium: arabic(base.displayMedium),
    displaySmall: arabic(base.displaySmall),
    headlineLarge: arabic(base.headlineLarge),
    headlineMedium: arabic(base.headlineMedium),
    headlineSmall: arabic(base.headlineSmall),
    titleLarge: arabic(base.titleLarge),
    titleMedium: arabic(base.titleMedium),
    titleSmall: arabic(base.titleSmall),
    bodyLarge: arabic(base.bodyLarge),
    bodyMedium: arabic(base.bodyMedium),
    bodySmall: arabic(base.bodySmall),
    labelLarge: arabic(base.labelLarge),
    labelMedium: arabic(base.labelMedium),
    labelSmall: arabic(base.labelSmall),
  );
}
