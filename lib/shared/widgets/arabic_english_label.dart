import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Stacks Arabic above a small gold English caption.
class ArabicEnglishLabel extends StatelessWidget {
  /// Creates a bilingual label column.
  const ArabicEnglishLabel({
    required this.arabicText,
    required this.englishText,
    super.key,
  });

  /// Arabic line (wrap with right-to-left directionality when needed).
  final String arabicText;

  /// English caption in gold label style.
  final String englishText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(arabicText, style: AppTextStyles.arabicLabel),
        ),
        Text(englishText, style: AppTextStyles.labelGold),
      ],
    );
  }
}
