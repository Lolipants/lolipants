import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Compact garment preview tile for home grids.
class StyleCard extends StatelessWidget {
  /// Creates a style tile with optional tap (e.g. open Browse).
  const StyleCard({
    required this.title,
    required this.subtitle,
    required this.imageColor,
    this.onTap,
    super.key,
  });

  /// Primary garment title.
  final String title;

  /// Secondary origin or region line.
  final String subtitle;

  /// Base swatch behind the arch motif.
  final Color imageColor;

  /// Optional navigation or preview action.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.md),
            ),
            child: SizedBox(
              height: 58,
              width: double.infinity,
              child: CustomPaint(
                painter: _MiniArchStripPainter(base: imageColor),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: card,
      ),
    );
  }
}

class _MiniArchStripPainter extends CustomPainter {
  _MiniArchStripPainter({required this.base});

  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = base;
    canvas.drawRect(Offset.zero & size, fill);

    final line = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    const count = 4;
    final step = size.width / count;
    for (var i = 0; i < count; i++) {
      final cx = step * (i + 0.5);
      final arcRect = Rect.fromCenter(
        center: Offset(cx, size.height * 1.05),
        width: step * 0.95,
        height: size.height * 1.35,
      );
      canvas.drawArc(arcRect, math.pi * 1.05, math.pi * 0.9, false, line);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniArchStripPainter oldDelegate) =>
      oldDelegate.base != base;
}
