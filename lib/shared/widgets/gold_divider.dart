import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';

/// Thin horizontal rule using the subtle gold border colour.
class GoldDivider extends StatelessWidget {
  /// Creates a full-width divider with optional fixed width (centred).
  const GoldDivider({
    this.width,
    this.height = 1,
    super.key,
  });

  /// When set, the line is centred with this width; otherwise it expands.
  final double? width;

  /// Thickness in logical pixels.
  final double height;

  @override
  Widget build(BuildContext context) {
    final line = Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.borderSubtle,
      ),
    );

    if (width != null) {
      return Center(
        child: SizedBox(width: width, child: line),
      );
    }

    return line;
  }
}
