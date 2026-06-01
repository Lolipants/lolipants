import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// List-tile style label: one language based on app locale.
class LocaleLabel extends ConsumerWidget {
  /// Creates a locale-aware label.
  const LocaleLabel({
    required this.en,
    required this.ar,
    super.key,
    this.style,
    this.destructive = false,
  });

  /// English copy.
  final String en;

  /// Arabic copy.
  final String ar;

  /// Optional override style.
  final TextStyle? style;

  /// Uses destructive (ruby) coloring when true.
  final bool destructive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final isAr = locale.languageCode == 'ar';
    final text = localizedFromLocale(locale, en, ar);
    final color = destructive ? AppColors.rubyLight : AppColors.sand;
    final textStyle = style ??
        (isAr
            ? AppTextStyles.arabicLabel.copyWith(color: color)
            : AppTextStyles.titleSmall.copyWith(color: color));
    final child = Text(text, style: textStyle);
    if (isAr) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      );
    }
    return child;
  }
}
