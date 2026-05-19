import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lolipants/core/assets/catalog_image_uri.dart';
import 'package:lolipants/core/constants/app_colors.dart';

/// Loads a catalogue image from R2 (when configured) or bundled assets.
class CatalogImage extends StatelessWidget {
  const CatalogImage({
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.errorWidget,
    super.key,
  });

  /// Bundled `assets/images/...` path or remote URL.
  final String path;

  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final networkUrl = catalogImageNetworkUrl(path);
    if (networkUrl != null) {
      return CachedNetworkImage(
        imageUrl: networkUrl,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => errorWidget ?? _defaultError(),
      );
    }

    final assetPath = catalogImageAssetPath(path);
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => errorWidget ?? _defaultError(),
      );
    }

    if (path.startsWith('/') || path.contains(':\\')) {
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => errorWidget ?? _defaultError(),
      );
    }

    return errorWidget ?? _defaultError();
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.stone.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultError() {
    return Container(
      width: width,
      height: height,
      color: AppColors.borderSubtle,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.gold),
    );
  }
}
