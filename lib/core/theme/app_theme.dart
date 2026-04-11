import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';

/// Builds the global dark [ThemeData] for Lolipants.
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.ink,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      surface: AppColors.stone,
      error: AppColors.rubyLight,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    useMaterial3: true,
  );
}
