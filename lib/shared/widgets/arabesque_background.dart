import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';

/// Decorative hex lattice inspired by arabesque tiling.
///
/// Renders behind screen content; pointer events are ignored.
class ArabesqueBackground extends StatelessWidget {
  /// Creates a low-contrast gold lattice.
  const ArabesqueBackground({
    this.opacity = 0.04,
    super.key,
  });

  /// Stroke alpha for the lattice lines (0.03–0.05 recommended).
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ArabesquePainter(opacity: opacity),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Draws a repeating flat-top hexagonal grid.
class _ArabesquePainter extends CustomPainter {
  /// Creates the painter with the given stroke opacity.
  _ArabesquePainter({required this.opacity});

  /// Alpha multiplier for [AppColors.gold] strokes.
  final double opacity;

  static const double _r = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.gold.withValues(alpha: opacity);

    final horiz = math.sqrt(3) * _r;
    const vert = 1.5 * _r;

    var row = 0;
    for (var y = -vert; y < size.height + vert; y += vert) {
      final offsetX = (row.isOdd ? horiz / 2 : 0.0);
      for (var x = -horiz; x < size.width + horiz; x += horiz) {
        final center = Offset(x + offsetX, y);
        _drawHex(canvas, center, _r, stroke);
      }
      row++;
    }
  }

  void _drawHex(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + math.pi / 3 * i;
      final px = c.dx + r * math.cos(angle);
      final py = c.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArabesquePainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
