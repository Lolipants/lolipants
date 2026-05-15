import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';

/// Renders a configurator option from CDN or bundled asset, optionally tinted.
class ConfiguratorOptionImage extends StatelessWidget {
  const ConfiguratorOptionImage({
    required this.option,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.primaryTint,
    this.accentTint,
    super.key,
  });

  final ConfiguratorOption option;
  final BoxFit fit;
  final Alignment alignment;
  final Color? primaryTint;
  final Color? accentTint;

  bool get _isTrimRole => option.metadata['role']?.toString() == 'trim';

  @override
  Widget build(BuildContext context) {
    final image = _buildImage();
    if (image == null) return const SizedBox.shrink();

    final tint = _isTrimRole ? accentTint : primaryTint;
    if (tint == null) return image;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        tint.withValues(alpha: 0.82),
        BlendMode.srcATop,
      ),
      child: image,
    );
  }

  Widget? _buildImage() {
    final url = option.assetUrl?.trim();
    if (url != null && url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        alignment: alignment,
      );
    }
    final bundled = option.bundledAssetPath;
    if (bundled != null) {
      return Image.asset(
        bundled,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.fog,
        ),
      );
    }
    return null;
  }
}

/// Mannequin body for build-mode hero (bundled asset, file, or remote).
class EditorMannequinBody extends StatelessWidget {
  const EditorMannequinBody({
    required this.assetPath,
    super.key,
  });

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    const fit = BoxFit.fitHeight;
    const align = Alignment.bottomCenter;
    if (assetPath.startsWith('assets/')) {
      return Image.asset(
        assetPath,
        fit: fit,
        alignment: align,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.person_outlined, color: AppColors.fog, size: 48),
        ),
      );
    }
    if (assetPath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: assetPath,
        fit: fit,
        alignment: align,
      );
    }
    return Image.file(
      File(assetPath),
      fit: fit,
      alignment: align,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.person_outlined, color: AppColors.fog, size: 48),
      ),
    );
  }
}
