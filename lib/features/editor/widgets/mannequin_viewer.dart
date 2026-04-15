import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

/// Render-only mannequin viewer for the Phase 3A shell.
class MannequinViewer extends StatelessWidget {
  const MannequinViewer({
    required this.garmentType,
    required this.primaryColour,
    required this.accentColour,
    this.textLayers = const <EditorTextLayer>[],
    this.selectedTextLayerId,
    this.onSelectTextLayer,
    this.onMoveTextLayer,
    this.printImagePath,
    this.customMannequinImagePath,
    this.printScale = 40,
    this.printPlacement = PrintPlacement.chest,
    super.key,
  });

  final String garmentType;
  final Color primaryColour;
  final Color accentColour;
  final List<EditorTextLayer> textLayers;
  final String? selectedTextLayerId;
  final ValueChanged<String>? onSelectTextLayer;
  final void Function({
    String? fontFamily,
    double? fontSize,
    Color? colour,
    Offset? placement,
  })? onMoveTextLayer;
  final String? printImagePath;
  final String? customMannequinImagePath;
  final double printScale;
  final PrintPlacement printPlacement;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * 0.6;
          final height = constraints.maxHeight * 0.9;
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 2.5,
            child: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MannequinPainter(
                          garmentType: garmentType,
                          primaryColour: primaryColour,
                          accentColour: accentColour,
                        ),
                      ),
                    ),
                    if (customMannequinImagePath != null)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.2,
                          child: _AdaptiveImage(path: customMannequinImagePath!),
                        ),
                      ),
                    if (printImagePath != null)
                      _PrintOverlay(
                        path: printImagePath!,
                        placement: printPlacement,
                        scalePercent: printScale,
                      ),
                    ...textLayers.map((layer) {
                      final left = (layer.placement.dx.clamp(0.1, 0.9) * width) - 55;
                      final top = (layer.placement.dy.clamp(0.2, 0.95) * height) - 14;
                      final selected = layer.id == selectedTextLayerId;
                      return Positioned(
                        left: left,
                        top: top,
                        child: GestureDetector(
                          onTap: onSelectTextLayer == null
                              ? null
                              : () => onSelectTextLayer!(layer.id),
                          onPanUpdate: onMoveTextLayer == null
                              ? null
                              : (details) {
                                  final nextX = ((left + details.delta.dx + 55) / width)
                                      .clamp(0.1, 0.9);
                                  final nextY = ((top + details.delta.dy + 14) / height)
                                      .clamp(0.2, 0.95);
                                  onMoveTextLayer!(
                                    placement: Offset(nextX, nextY),
                                  );
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: selected
                                ? BoxDecoration(
                                    border: Border.all(color: AppColors.gold),
                                    borderRadius: BorderRadius.circular(4),
                                  )
                                : null,
                            child: Text(
                              layer.text,
                              style: TextStyle(
                                fontFamily: layer.fontFamily,
                                fontSize: layer.fontSize,
                                color: layer.colour,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MannequinPainter extends CustomPainter {
  _MannequinPainter({
    required this.garmentType,
    required this.primaryColour,
    required this.accentColour,
  });

  final String garmentType;
  final Color primaryColour;
  final Color accentColour;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = accentColour;
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.borderStrong;

    final headRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.12),
      width: size.width * 0.18,
      height: size.width * 0.18,
    );
    canvas.drawOval(headRect, fillPaint..color = AppColors.smoke);
    canvas.drawOval(headRect, outlinePaint);

    switch (garmentType.toLowerCase()) {
      case 'abaya':
        _paintAbaya(canvas, size, fillPaint, accentPaint, outlinePaint);
      case 'bisht':
        _paintThobe(canvas, size, fillPaint, accentPaint, outlinePaint);
        _paintBishtCloak(canvas, size, fillPaint, accentPaint, outlinePaint);
      case 'kandura':
        _paintKandura(canvas, size, fillPaint, accentPaint, outlinePaint);
      case 'suit':
        _paintSuit(canvas, size, fillPaint, accentPaint, outlinePaint);
      case 'thobe':
      default:
        _paintThobe(canvas, size, fillPaint, accentPaint, outlinePaint);
    }
  }

  void _paintThobe(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint accent,
    Paint outline,
  ) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        size.width * 0.26,
        size.height * 0.2,
        size.width * 0.74,
        size.height * 0.9,
      ),
      const Radius.circular(18),
    );
    fill.color = primaryColour;
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, outline);
    _paintSleeves(canvas, size, fill, outline);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.24),
      Offset(size.width * 0.5, size.height * 0.86),
      outline,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.22),
      Offset(size.width * 0.5, size.height * 0.25),
      accent,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.22),
      Offset(size.width * 0.5, size.height * 0.25),
      accent,
    );
  }

  void _paintAbaya(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint accent,
    Paint outline,
  ) {
    fill.color = primaryColour;
    final path = Path()
      ..moveTo(size.width * 0.32, size.height * 0.22)
      ..lineTo(size.width * 0.68, size.height * 0.22)
      ..lineTo(size.width * 0.83, size.height * 0.9)
      ..lineTo(size.width * 0.17, size.height * 0.9)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);
    _paintSleeves(canvas, size, fill, outline);
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.84),
      Offset(size.width * 0.72, size.height * 0.84),
      accent,
    );
    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.87),
      Offset(size.width * 0.74, size.height * 0.87),
      accent,
    );
  }

  void _paintBishtCloak(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint accent,
    Paint outline,
  ) {
    fill.color = primaryColour.withValues(alpha: 0.6);
    final cloak = Path()
      ..moveTo(size.width * 0.2, size.height * 0.22)
      ..lineTo(size.width * 0.8, size.height * 0.22)
      ..lineTo(size.width * 0.86, size.height * 0.88)
      ..lineTo(size.width * 0.14, size.height * 0.88)
      ..close();
    canvas.drawPath(cloak, fill);
    canvas.drawPath(cloak, outline);
    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.28 + i * 0.08);
      canvas.drawLine(
        Offset(size.width * 0.26, y),
        Offset(size.width * 0.74, y + size.height * 0.03),
        accent,
      );
    }
  }

  void _paintKandura(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint accent,
    Paint outline,
  ) {
    fill.color = primaryColour;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        size.width * 0.28,
        size.height * 0.2,
        size.width * 0.72,
        size.height * 0.78,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, outline);
    _paintSleeves(canvas, size, fill, outline, lower: 0.62);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.24),
        width: size.width * 0.16,
        height: size.height * 0.05,
      ),
      0,
      3.14,
      false,
      accent,
    );
  }

  void _paintSuit(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint accent,
    Paint outline,
  ) {
    fill.color = primaryColour;
    final jacket = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        size.width * 0.29,
        size.height * 0.22,
        size.width * 0.71,
        size.height * 0.62,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(jacket, fill);
    canvas.drawRRect(jacket, outline);
    _paintSleeves(canvas, size, fill, outline, lower: 0.62);
    final tie = Path()
      ..moveTo(size.width * 0.5, size.height * 0.28)
      ..lineTo(size.width * 0.47, size.height * 0.38)
      ..lineTo(size.width * 0.53, size.height * 0.38)
      ..close();
    final tieTail = Path()
      ..moveTo(size.width * 0.47, size.height * 0.38)
      ..lineTo(size.width * 0.53, size.height * 0.38)
      ..lineTo(size.width * 0.5, size.height * 0.54)
      ..close();
    fill.color = accentColour;
    canvas.drawPath(tie, fill);
    canvas.drawPath(tieTail, fill);
    fill.color = primaryColour;
    final trouserLeft = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        size.width * 0.36,
        size.height * 0.62,
        size.width * 0.48,
        size.height * 0.9,
      ),
      const Radius.circular(8),
    );
    final trouserRight = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        size.width * 0.52,
        size.height * 0.62,
        size.width * 0.64,
        size.height * 0.9,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(trouserLeft, fill);
    canvas.drawRRect(trouserRight, fill);
    canvas.drawRRect(trouserLeft, outline);
    canvas.drawRRect(trouserRight, outline);
  }

  void _paintSleeves(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint outline, {
    double lower = 0.68,
  }) {
    final leftSleeve = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        size.width * 0.12,
        size.height * 0.26,
        size.width * 0.25,
        size.height * lower,
      ),
      const Radius.circular(14),
    );
    final rightSleeve = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        size.width * 0.75,
        size.height * 0.26,
        size.width * 0.88,
        size.height * lower,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(leftSleeve, fill);
    canvas.drawRRect(rightSleeve, fill);
    canvas.drawRRect(leftSleeve, outline);
    canvas.drawRRect(rightSleeve, outline);
  }

  @override
  bool shouldRepaint(covariant _MannequinPainter oldDelegate) {
    return oldDelegate.garmentType != garmentType ||
        oldDelegate.primaryColour != primaryColour ||
        oldDelegate.accentColour != accentColour;
  }
}

/// Mini mannequin used by selector cards.
class MiniMannequin extends StatelessWidget {
  const MiniMannequin({
    required this.primaryColour,
    required this.accentColour,
    super.key,
  });

  final Color primaryColour;
  final Color accentColour;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: CustomPaint(
        painter: _MannequinPainter(
          garmentType: 'thobe',
          primaryColour: primaryColour,
          accentColour: accentColour,
        ),
      ),
    );
  }
}

/// Placeholder panel body while 3B widgets are pending.
class EditorPlaceholderPanel extends StatelessWidget {
  const EditorPlaceholderPanel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(label, style: AppTextStyles.bodyMedium),
      ),
    );
  }
}

class _PrintOverlay extends StatelessWidget {
  const _PrintOverlay({
    required this.path,
    required this.placement,
    required this.scalePercent,
  });

  final String path;
  final PrintPlacement placement;
  final double scalePercent;

  @override
  Widget build(BuildContext context) {
    final alignment = switch (placement) {
      PrintPlacement.chest => Alignment.topCenter,
      PrintPlacement.back => Alignment.center,
      PrintPlacement.fullFront => Alignment.center,
    };
    final size = switch (placement) {
      PrintPlacement.fullFront => scalePercent / 100 * 220,
      _ => scalePercent / 100 * 140,
    };
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(top: placement == PrintPlacement.chest ? 90 : 120),
        child: Opacity(
          opacity: 0.9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: _AdaptiveImage(
              path: path,
              width: size,
              height: size,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdaptiveImage extends StatelessWidget {
  const _AdaptiveImage({
    required this.path,
    this.width,
    this.height,
  });

  final String path;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isRemote = path.startsWith('http://') || path.startsWith('https://');
    if (isRemote) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.borderSubtle,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.gold),
    );
  }
}
