import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/features/editor/models/print_placement.dart';
import 'package:lolipants/features/editor/widgets/editor_layer_resize_wrapper.dart'
    show EditorLayerResizeWrapper, EditorResizeDragCallback;

/// Print graphic placed on a garment preview (mannequin or flat-lay).
class EditorPrintOverlay extends StatelessWidget {
  const EditorPrintOverlay({
    required this.path,
    required this.placement,
    required this.scalePercent,
    required this.offsetX,
    required this.offsetY,
    this.onDragUpdate,
    this.onResize,
    this.onTap,
    this.selected = false,
    this.chestTopPadding = 90,
    this.defaultTopPadding = 120,
    super.key,
  });

  final String path;
  final PrintPlacement placement;
  final double scalePercent;
  final double offsetX;
  final double offsetY;
  final ValueChanged<Offset>? onDragUpdate;
  final EditorResizeDragCallback? onResize;
  final VoidCallback? onTap;
  final bool selected;
  final double chestTopPadding;
  final double defaultTopPadding;

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
    final baseTop = placement == PrintPlacement.chest
        ? chestTopPadding
        : defaultTopPadding;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(top: baseTop),
        child: Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: EditorLayerResizeWrapper(
            selected: selected,
            contentSize: Size(size, size),
            onTap: onTap,
            onResize: selected ? onResize : null,
            onMove: selected ? onDragUpdate : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.92),
                  BlendMode.modulate,
                ),
                child: Opacity(
                  opacity: 0.88,
                  child: EditorAdaptiveImage(
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

/// Asset, file, or remote image for editor overlays.
class EditorAdaptiveImage extends StatelessWidget {
  const EditorAdaptiveImage({
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    final isRemote = path.startsWith('http://') || path.startsWith('https://');
    if (isRemote) {
      return CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        errorWidget: (_, __, ___) => _fallback(),
      );
    }
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
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
