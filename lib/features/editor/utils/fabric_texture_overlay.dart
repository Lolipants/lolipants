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

/// Default on-screen width of one swatch tile in logical pixels.
const double kFabricPreviewTileLogicalPx = 60;

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
    this.tileLogicalPixels = kFabricPreviewTileLogicalPx,
    this.loadingChild,
    super.key,
  });

  final ImageProvider maskImageProvider;
  final ImageProvider fabricImageProvider;
  final BoxFit fit;
  final Alignment alignment;
  final double tileLogicalPixels;

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
        tileLogicalPixels: widget.tileLogicalPixels,
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
    required this.tileLogicalPixels,
  });

  final ui.Image mask;
  final double maskScale;
  final ui.Image fabric;
  final BoxFit fit;
  final Alignment alignment;
  final double tileLogicalPixels;

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
        ..blendMode = BlendMode.srcATop
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
    final tileW = tileLogicalPixels;
    final tileH = tileW * fabric.height / fabric.width;

    // Skip compressed JPEG border pixels (cause white/dark seam grids when tiled).
    // Stretch the inner swatch to each tile — no dest overlap (overlap + multiply = dark bands).
    const borderSkip = 2.0;
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
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;

    final cols = (dest.width / tileW).ceil() + 1;
    final rows = (dest.height / tileH).ceil() + 1;

    canvas.save();
    canvas.clipRect(dest);
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        canvas.drawImageRect(
          fabric,
          fabricSrc,
          Rect.fromLTWH(
            dest.left + (col * tileW),
            dest.top + (row * tileH),
            tileW,
            tileH,
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
        oldDelegate.tileLogicalPixels != tileLogicalPixels;
  }
}
