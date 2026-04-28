import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';

/// Rounded-rectangle long button used by the Home "Traditional styles" block
/// and the Browse tab to launch the editor pre-seeded with a regional preset.
///
/// Replaces the earlier 2x2 grids of `StyleCard` / `CountryCard`.
class RegionStyleButton extends StatelessWidget {
  const RegionStyleButton({
    super.key,
    required this.preset,
    this.onTap,
  });

  final RegionStylePreset preset;

  /// Optional override. When null, tapping pushes `/editor` with an
  /// [EditorPresetArgs] extra so the editor seeds from the preset.
  final VoidCallback? onTap;

  void _defaultTap(BuildContext context) {
    final presetArgs = EditorPresetArgs(
      presetId: preset.id,
      designName: preset.title,
      garmentType: preset.garmentType,
      primaryColour: preset.primaryColour,
      accentColour: preset.accentColour,
      fabricId: preset.fabricId,
    );
    context.push(
      '/editor',
      extra: EditorBootstrapArgs(
        source: 'preset_catalog',
        mannequinId: presetArgs.mannequinId,
        preset: presetArgs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${preset.title}. ${preset.subtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _defaultTap(context),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.stone,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _RegionPatch(preset: preset),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.gold,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionPatch extends StatelessWidget {
  const _RegionPatch({required this.preset});

  final RegionStylePreset preset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: RegionPatternPainter(
            primary: preset.primaryColour,
            accent: preset.accentColour,
            region: preset.region,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Paints a small regional ornament on the square patch that leads each
/// [RegionStyleButton]. Uses geometric primitives only (no image assets) so
/// the widget stays self-contained.
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
        break;
      case Region.levant:
        _paintLevantZellige(canvas, size, ornament);
        break;
      case Region.maghreb:
        _paintMaghrebDiamonds(canvas, size, ornament);
        break;
      case Region.modern:
        _paintModernLines(canvas, size, ornament);
        break;
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
