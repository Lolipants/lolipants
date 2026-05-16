import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';

/// Geometric fallback when a preset preview image is missing.
class RegionPresetPatternFallback extends StatelessWidget {
  const RegionPresetPatternFallback({required this.preset, super.key});

  final RegionStylePreset preset;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RegionPatternPainter(
        primary: preset.primaryColour,
        accent: preset.accentColour,
        region: preset.region,
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Paints a small regional ornament when no bundled preview image is available.
class RegionPatternPainter extends CustomPainter {
  RegionPatternPainter({
    required this.primary,
    required this.accent,
    required this.region,
  });

  final Color primary;
  final Color accent;
  final Region region;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = primary;
    canvas.drawRect(Offset.zero & size, bg);

    final ornament = Paint()
      ..color = accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    switch (region) {
      case Region.gulf:
        _paintGulfArches(canvas, size, ornament);
      case Region.levant:
        _paintLevantZellige(canvas, size, ornament);
      case Region.maghreb:
        _paintMaghrebDiamonds(canvas, size, ornament);
      case Region.modern:
        _paintModernLines(canvas, size, ornament);
    }
  }

  void _paintGulfArches(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    for (var i = 0; i < 3; i++) {
      final y = h * (0.35 + 0.22 * i);
      final path = Path()
        ..moveTo(w * 0.08, y)
        ..quadraticBezierTo(w * 0.5, y - h * 0.28, w * 0.92, y);
      canvas.drawPath(path, paint);
    }
  }

  void _paintLevantZellige(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = math.min(w, h) * 0.35;
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();
    final star2 = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + math.pi / 8;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        star2.moveTo(x, y);
      } else {
        star2.lineTo(x, y);
      }
    }
    star2.close();
    canvas.drawPath(star, paint);
    canvas.drawPath(star2, paint);
  }

  void _paintMaghrebDiamonds(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    for (var i = -2; i <= 2; i++) {
      final cx = w / 2 + i * w * 0.22;
      final diamond = Path()
        ..moveTo(cx, h * 0.15)
        ..lineTo(cx + w * 0.1, h * 0.5)
        ..lineTo(cx, h * 0.85)
        ..lineTo(cx - w * 0.1, h * 0.5)
        ..close();
      canvas.drawPath(diamond, paint);
    }
  }

  void _paintModernLines(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    for (var i = 1; i < 5; i++) {
      final y = h * i / 5;
      canvas.drawLine(Offset(w * 0.1, y), Offset(w * 0.9, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant RegionPatternPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.accent != accent ||
        oldDelegate.region != region;
  }
}
