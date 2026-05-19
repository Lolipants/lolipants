import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/built_in_mannequin_assets.dart';
import 'package:lolipants/features/editor/data/editor_text_fonts.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

/// Render-only mannequin viewer for the Phase 3A shell.
class MannequinViewer extends StatelessWidget {
  const MannequinViewer({
    required this.mannequinId,
    required this.garmentType,
    required this.primaryColour,
    required this.accentColour,
    this.fabricProfile = 'standard',
    this.textLayers = const <EditorTextLayer>[],
    this.selectedTextLayerId,
    this.onSelectTextLayer,
    this.onMoveTextLayer,
    this.printImagePath,
    this.customMannequinImagePath,
    this.printScale = 40,
    this.printPlacement = PrintPlacement.chest,
    this.printOffsetX = 0,
    this.printOffsetY = 0,
    this.onMovePrintImage,
    super.key,
  });

  /// Local or API mannequin id; used to resolve bundled body assets.
  final String mannequinId;
  final String garmentType;
  final Color primaryColour;
  final Color accentColour;
  final String fabricProfile;
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
  final double printOffsetX;
  final double printOffsetY;
  final ValueChanged<Offset>? onMovePrintImage;

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
                    // Reference body: user photo replaces bundled asset when set.
                    if (customMannequinImagePath != null)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.85,
                          child:
                              _AdaptiveImage(path: customMannequinImagePath!),
                        ),
                      )
                    else if (builtInMannequinAssetPath(mannequinId) != null)
                      Positioned.fill(
                        child: ColoredBox(
                          // Transparent PNG mannequins read on dark compose card.
                          color: const Color(0xFFE8E4EA),
                          child: CatalogImage(
                            path: builtInMannequinAssetPath(mannequinId)!,
                            fit: BoxFit.contain,
                            errorWidget: const Center(
                              child: Icon(
                                Icons.person_outlined,
                                color: AppColors.fog,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (customMannequinImagePath == null &&
                        builtInMannequinAssetPath(mannequinId) == null)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MannequinPainter(
                            garmentType: garmentType,
                            primaryColour: primaryColour,
                            accentColour: accentColour,
                            fabricProfile: fabricProfile,
                          ),
                        ),
                      ),
                    if (printImagePath != null)
                      _PrintOverlay(
                        path: printImagePath!,
                        placement: printPlacement,
                        scalePercent: printScale,
                        offsetX: printOffsetX,
                        offsetY: printOffsetY,
                        onDragUpdate: onMovePrintImage,
                      ),
                    ...textLayers.map((layer) {
                      final left =
                          (layer.placement.dx.clamp(0.1, 0.9) * width) - 55;
                      final top =
                          (layer.placement.dy.clamp(0.2, 0.95) * height) - 14;
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
                                  final nextX =
                                      ((left + details.delta.dx + 55) / width)
                                          .clamp(0.1, 0.9);
                                  final nextY =
                                      ((top + details.delta.dy + 14) / height)
                                          .clamp(0.2, 0.95);
                                  onMoveTextLayer!(
                                    placement: Offset(nextX, nextY),
                                  );
                                },
                          child: Transform.rotate(
                            angle: layer.rotation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: selected
                                  ? BoxDecoration(
                                      border: Border.all(color: AppColors.gold),
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                  : null,
                              child: Text(
                                layer.text,
                                style: editorLayerTextStyle(
                                  fontFamily: layer.fontFamily,
                                  fontSize: layer.fontSize,
                                  color: layer.colour,
                                ).copyWith(
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                      offset: Offset(0.8, 0.8),
                                    ),
                                  ],
                                ),
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
    required this.fabricProfile,
  });

  final String garmentType;
  final Color primaryColour;
  final Color accentColour;
  final String fabricProfile;

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

    final profile = fabricProfile.toLowerCase().trim();
    final gloss = switch (profile) {
      'premium' => 0.20,
      'luxury' => 0.26,
      _ => 0.14,
    };

    switch (garmentType.toLowerCase()) {
      case 'abaya':
        _paintAbaya(canvas, size, fillPaint, accentPaint, outlinePaint, gloss);
      case 'bisht':
        _paintThobe(canvas, size, fillPaint, accentPaint, outlinePaint, gloss);
        _paintBishtCloak(
            canvas, size, fillPaint, accentPaint, outlinePaint, gloss);
      case 'kandura':
        _paintKandura(
            canvas, size, fillPaint, accentPaint, outlinePaint, gloss);
      case 'suit':
        _paintSuit(canvas, size, fillPaint, accentPaint, outlinePaint, gloss);
      case 'thobe':
      default:
        _paintThobe(canvas, size, fillPaint, accentPaint, outlinePaint, gloss);
    }
  }

  void _paintThobe(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint accent,
    Paint outline,
    double gloss,
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
    _paintFabricLighting(
      canvas,
      size,
      Path()..addRRect(body),
      gloss: gloss,
    );
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
    _paintSeamLine(
      canvas,
      Offset(size.width * 0.5, size.height * 0.24),
      Offset(size.width * 0.5, size.height * 0.86),
    );
  }

  void _paintAbaya(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint accent,
    Paint outline,
    double gloss,
  ) {
    fill.color = primaryColour;
    final path = Path()
      ..moveTo(size.width * 0.32, size.height * 0.22)
      ..lineTo(size.width * 0.68, size.height * 0.22)
      ..lineTo(size.width * 0.83, size.height * 0.9)
      ..lineTo(size.width * 0.17, size.height * 0.9)
      ..close();
    canvas.drawPath(path, fill);
    _paintFabricLighting(canvas, size, path, gloss: gloss);
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
    double gloss,
  ) {
    fill.color = primaryColour.withValues(alpha: 0.6);
    final cloak = Path()
      ..moveTo(size.width * 0.2, size.height * 0.22)
      ..lineTo(size.width * 0.8, size.height * 0.22)
      ..lineTo(size.width * 0.86, size.height * 0.88)
      ..lineTo(size.width * 0.14, size.height * 0.88)
      ..close();
    canvas.drawPath(cloak, fill);
    _paintFabricLighting(canvas, size, cloak, gloss: gloss * 0.8);
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
    double gloss,
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
    _paintFabricLighting(
      canvas,
      size,
      Path()..addRRect(body),
      gloss: gloss,
    );
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
    double gloss,
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
    _paintFabricLighting(
      canvas,
      size,
      Path()..addRRect(jacket),
      gloss: gloss,
    );
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
    _paintFabricLighting(
      canvas,
      size,
      Path()
        ..addRRect(leftSleeve)
        ..addRRect(rightSleeve),
      gloss: 0.10,
    );
    canvas.drawRRect(leftSleeve, outline);
    canvas.drawRRect(rightSleeve, outline);
  }

  void _paintFabricLighting(
    Canvas canvas,
    Size size,
    Path clipPath, {
    required double gloss,
  }) {
    // Cheap "material" depth: multiply shadow + subtle highlight stripe.
    final bounds = clipPath.getBounds();
    canvas.save();
    canvas.clipPath(clipPath);

    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.00),
          Colors.black.withValues(alpha: 0.10 + gloss),
        ],
      ).createShader(bounds)
      ..blendMode = BlendMode.multiply;
    canvas.drawRect(bounds, shadowPaint);

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.00),
          Colors.white.withValues(alpha: gloss),
          Colors.white.withValues(alpha: 0.00),
        ],
        stops: const [0.25, 0.5, 0.75],
      ).createShader(bounds)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(bounds, highlightPaint);

    canvas.restore();
  }

  void _paintSeamLine(Canvas canvas, Offset a, Offset b) {
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black.withValues(alpha: 0.10);
    canvas.drawLine(a, b, seam);
  }

  @override
  bool shouldRepaint(covariant _MannequinPainter oldDelegate) {
    return oldDelegate.garmentType != garmentType ||
        oldDelegate.primaryColour != primaryColour ||
        oldDelegate.accentColour != accentColour ||
        oldDelegate.fabricProfile != fabricProfile;
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
          fabricProfile: 'standard',
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
    required this.offsetX,
    required this.offsetY,
    this.onDragUpdate,
  });

  final String path;
  final PrintPlacement placement;
  final double scalePercent;
  final double offsetX;
  final double offsetY;
  final ValueChanged<Offset>? onDragUpdate;

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
        padding: EdgeInsets.only(
          top: (placement == PrintPlacement.chest ? 90 : 120) + offsetY,
        ),
        child: GestureDetector(
          onPanUpdate: onDragUpdate == null
              ? null
              : (details) => onDragUpdate!(details.delta),
          child: Transform.translate(
            offset: Offset(offsetX, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: ColorFiltered(
                // Slight modulate helps the print feel like it sits on fabric.
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.92),
                  BlendMode.modulate,
                ),
                child: Opacity(
                  opacity: 0.88,
                  child: _AdaptiveImage(
                    path: path,
                    width: size,
                    height: size,
                  ),
                ),
              ),
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
    return CatalogImage(
      path: path,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorWidget: _fallback(),
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
