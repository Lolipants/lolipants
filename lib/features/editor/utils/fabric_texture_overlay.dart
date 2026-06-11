import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:lolipants/core/assets/catalog_image_uri.dart';
import 'package:lolipants/features/editor/data/bundled_fabric_catalog.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/models/fabric_option.dart';

/// Resolves a swatch [ImageProvider] from API/bundled paths.
ImageProvider? fabricSwatchImageProvider(FabricOption fabric) {
  final raw = fabric.swatchUrl.trim().isNotEmpty
      ? fabric.swatchUrl.trim()
      : (bundledFabricSwatchPath(fabric.id) ?? '');
  if (raw.isEmpty) return null;

  return catalogPathImageProvider(raw);
}

/// Resolves catalogue/bundled paths to an [ImageProvider].
ImageProvider? catalogPathImageProvider(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return null;

  final assetPath = catalogImageAssetPath(trimmed);
  if (assetPath != null) return AssetImage(assetPath);

  final networkUrl = catalogImageNetworkUrl(trimmed);
  if (networkUrl != null) return CachedNetworkImageProvider(networkUrl);

  return null;
}

/// Resolves a configurator layer asset to an [ImageProvider].
ImageProvider? configuratorOptionImageProvider(ConfiguratorOption option) {
  final url = option.assetUrl?.trim();
  if (url != null && url.startsWith('http')) {
    return catalogPathImageProvider(url) ??
        CachedNetworkImageProvider(url);
  }
  final bundled = option.bundledAssetPath;
  if (bundled != null) {
    return catalogPathImageProvider(bundled);
  }
  return null;
}

/// Selected fabric from [availableFabrics], or null when none picked.
FabricOption? selectedFabricOption({
  required String selectedFabricId,
  required List<FabricOption> availableFabrics,
}) {
  if (selectedFabricId.trim().isEmpty) return null;
  for (final f in availableFabrics) {
    if (f.id == selectedFabricId) return f;
  }
  return null;
}

/// Minimum / maximum on-screen fabric tile width in logical pixels.
const double kFabricTileMinLogicalPx = 32;
const double kFabricTileMaxLogicalPx = 48;

/// Evenly-divided tile grid for a garment [dest] rect.
class FabricTileGrid {
  const FabricTileGrid({
    required this.tileW,
    required this.tileH,
    required this.cols,
    required this.rows,
  });

  final double tileW;
  final double tileH;
  final int cols;
  final int rows;
}

/// Computes tile dimensions that evenly divide [dest] with ~[targetRepeats] across
/// the shorter garment edge.
FabricTileGrid fabricTileGridForDest(
  Rect dest,
  double fabricAspect, {
  int targetRepeats = 5,
}) {
  if (dest.width <= 0 || dest.height <= 0 || fabricAspect <= 0) {
    return const FabricTileGrid(tileW: 40, tileH: 40, cols: 1, rows: 1);
  }

  final shorter = dest.width < dest.height ? dest.width : dest.height;
  var tileW = (shorter / targetRepeats).clamp(
    kFabricTileMinLogicalPx,
    kFabricTileMaxLogicalPx,
  );

  final cols = (dest.width / tileW).round().clamp(2, 999);
  tileW = dest.width / cols;

  final rawTileH = tileW * fabricAspect;
  final rows = (dest.height / rawTileH).round().clamp(2, 999);
  final tileH = dest.height / rows;

  return FabricTileGrid(tileW: tileW, tileH: tileH, cols: cols, rows: rows);
}

/// Slight lift so [BlendMode.multiply] patterns stay visible on shaded masks.
const ColorFilter kFabricMultiplyBrightnessFilter = ColorFilter.matrix(<double>[
  1.12, 0, 0, 0, 16,
  0, 1.12, 0, 0, 16,
  0, 0, 1.12, 0, 16,
  0, 0, 0, 1, 0,
]);

/// Matches [Image] / [paintImage] placement for configurator hero layers.
Rect configuratorLayerDestRect({
  required ui.Image image,
  required double scale,
  required Size canvasSize,
  required BoxFit fit,
  required Alignment alignment,
}) {
  final inputSize = Size(
    image.width.toDouble() / scale,
    image.height.toDouble() / scale,
  );
  final fitted = applyBoxFit(fit, inputSize, canvasSize);
  return alignment.inscribe(
    fitted.destination,
    Offset.zero & canvasSize,
  );
}

/// Draws a tiled fabric swatch clipped to a garment/catalogue mask image.
class FabricTextureOverlay extends StatefulWidget {
  const FabricTextureOverlay({
    required this.maskImageProvider,
    required this.fabricImageProvider,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.targetRepeats = 5,
    this.loadingChild,
    super.key,
  });

  final ImageProvider maskImageProvider;
  final ImageProvider fabricImageProvider;
  final BoxFit fit;
  final Alignment alignment;

  /// Approximate swatch repeats across the shorter garment edge.
  final int targetRepeats;

  /// Placeholder while mask and fabric images decode.
  final Widget? loadingChild;

  @override
  State<FabricTextureOverlay> createState() => _FabricTextureOverlayState();
}

class _FabricTextureOverlayState extends State<FabricTextureOverlay> {
  ui.Image? _maskImage;
  ui.Image? _fabricImage;
  double _maskScale = 1;
  ImageStream? _maskStream;
  ImageStream? _fabricStream;
  ImageStreamListener? _maskListener;
  ImageStreamListener? _fabricListener;

  bool get _imagesReady => _maskImage != null && _fabricImage != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenForImages();
  }

  @override
  void didUpdateWidget(FabricTextureOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maskImageProvider != widget.maskImageProvider ||
        oldWidget.fabricImageProvider != widget.fabricImageProvider) {
      _listenForImages();
    }
  }

  @override
  void dispose() {
    _detachListeners();
    super.dispose();
  }

  void _detachListeners() {
    if (_maskStream != null && _maskListener != null) {
      _maskStream!.removeListener(_maskListener!);
    }
    if (_fabricStream != null && _fabricListener != null) {
      _fabricStream!.removeListener(_fabricListener!);
    }
    _maskStream = null;
    _fabricStream = null;
    _maskListener = null;
    _fabricListener = null;
  }

  void _listenForImages() {
    _detachListeners();
    _maskImage = null;
    _fabricImage = null;
    _maskScale = 1;

    final config = createLocalImageConfiguration(context);

    _maskStream = widget.maskImageProvider.resolve(config);
    _maskListener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() {
        _maskImage = info.image;
        _maskScale = info.scale;
      });
    });
    _maskStream!.addListener(_maskListener!);

    _fabricStream = widget.fabricImageProvider.resolve(config);
    _fabricListener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _fabricImage = info.image);
    });
    _fabricStream!.addListener(_fabricListener!);
  }

  @override
  Widget build(BuildContext context) {
    if (!_imagesReady) {
      return widget.loadingChild ?? const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _MaskedFabricTilePainter(
        mask: _maskImage!,
        maskScale: _maskScale,
        fabric: _fabricImage!,
        fit: widget.fit,
        alignment: widget.alignment,
        targetRepeats: widget.targetRepeats,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _MaskedFabricTilePainter extends CustomPainter {
  _MaskedFabricTilePainter({
    required this.mask,
    required this.maskScale,
    required this.fabric,
    required this.fit,
    required this.alignment,
    required this.targetRepeats,
  });

  final ui.Image mask;
  final double maskScale;
  final ui.Image fabric;
  final BoxFit fit;
  final Alignment alignment;
  final int targetRepeats;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final dest = configuratorLayerDestRect(
      image: mask,
      scale: maskScale,
      canvasSize: size,
      fit: fit,
      alignment: alignment,
    );

    canvas.saveLayer(rect, Paint());

    painting.paintImage(
      canvas: canvas,
      rect: rect,
      image: mask,
      scale: maskScale,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
    );

    _paintTiledFabric(
      canvas,
      dest,
      Paint()
        ..blendMode = BlendMode.multiply
        ..filterQuality = FilterQuality.medium,
    );

    painting.paintImage(
      canvas: canvas,
      rect: rect,
      image: mask,
      scale: maskScale,
      fit: fit,
      alignment: alignment,
      blendMode: BlendMode.dstIn,
    );

    canvas.restore();
  }

  void _paintTiledFabric(Canvas canvas, Rect dest, Paint paint) {
    final fabricAspect = fabric.height / fabric.width;
    final grid = fabricTileGridForDest(
      dest,
      fabricAspect,
      targetRepeats: targetRepeats,
    );

    // Skip compressed JPEG border pixels (cause white/dark seam grids when tiled).
    // Stretch the inner swatch to each tile — no dest overlap (overlap + multiply = dark bands).
    const borderSkip = 4.0;
    final innerW = fabric.width.toDouble() - (borderSkip * 2);
    final innerH = fabric.height.toDouble() - (borderSkip * 2);
    final fabricSrc = innerW > 0 && innerH > 0
        ? Rect.fromLTWH(borderSkip, borderSkip, innerW, innerH)
        : Rect.fromLTWH(
            0,
            0,
            fabric.width.toDouble(),
            fabric.height.toDouble(),
          );

    final tilePaint = Paint()
      ..blendMode = paint.blendMode
      ..colorFilter = kFabricMultiplyBrightnessFilter
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;

    final startCol = (dest.left / grid.tileW).floor();
    final endCol = ((dest.right - 0.001) / grid.tileW).ceil();
    final startRow = (dest.top / grid.tileH).floor();
    final endRow = ((dest.bottom - 0.001) / grid.tileH).ceil();

    canvas.save();
    canvas.clipRect(dest);
    for (var row = startRow; row <= endRow; row++) {
      for (var col = startCol; col <= endCol; col++) {
        canvas.drawImageRect(
          fabric,
          fabricSrc,
          Rect.fromLTWH(
            col * grid.tileW,
            row * grid.tileH,
            grid.tileW,
            grid.tileH,
          ),
          tilePaint,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MaskedFabricTilePainter oldDelegate) {
    return oldDelegate.mask != mask ||
        oldDelegate.maskScale != maskScale ||
        oldDelegate.fabric != fabric ||
        oldDelegate.fit != fit ||
        oldDelegate.alignment != alignment ||
        oldDelegate.targetRepeats != targetRepeats;
  }
}
