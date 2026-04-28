import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';

/// Builds the global dark [ThemeData] for Lolipants.
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.ink,
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
  );
}
