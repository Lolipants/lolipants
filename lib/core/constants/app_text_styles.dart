import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';

/// Typography tokens using Poppins (Latin) and Noto Naskh Arabic.
class AppTextStyles {
  AppTextStyles._();

  static const String _latin = 'Poppins';
  static const String _arabic = 'NotoNaskhArabic';

  /// Large marketing display.
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: _latin,
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: AppColors.sand,
      );

  /// Medium display heading.
  static TextStyle get displayMedium => const TextStyle(
        fontFamily: _latin,
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.sand,
      );

  /// Section title.
  static TextStyle get titleLarge => const TextStyle(
        fontFamily: _latin,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.sand,
      );

  /// Subsection title.
  static TextStyle get titleMedium => const TextStyle(
        fontFamily: _latin,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.sand,
      );

  /// Compact title.
  static TextStyle get titleSmall => const TextStyle(
        fontFamily: _latin,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.sand,
      );

  /// Primary body copy.
  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: _latin,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.sand,
      );

  /// Secondary body copy.
  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: _latin,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.dust,
      );

  /// Tertiary / caption body.
  static TextStyle get bodySmall => const TextStyle(
        fontFamily: _latin,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.fog,
      );

  /// Small uppercase-style label in gold.
  static TextStyle get labelGold => const TextStyle(
        fontFamily: _latin,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.gold,
        letterSpacing: 0.1,
      );

  /// Arabic body copy.
  static TextStyle get arabicBody => const TextStyle(
        fontFamily: _arabic,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.sand,
      );

  /// Arabic label in gold.
  static TextStyle get arabicLabel => const TextStyle(
        fontFamily: _arabic,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.gold,
      );
}
