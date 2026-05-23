import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/utils/layer_tint.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';

/// Renders a configurator option from CDN or bundled asset at native colours
/// unless [tintColor] is set.
class ConfiguratorOptionImage extends StatelessWidget {
  const ConfiguratorOptionImage({
    required this.option,
    this.tintColor,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    super.key,
  });

  final ConfiguratorOption option;
  final Color? tintColor;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final image = _buildImage();
    if (image == null) return const SizedBox.shrink();
    return applyLayerTint(child: image, tintColor: tintColor);
  }

  Widget? _buildImage() {
    final url = option.assetUrl?.trim();
    if (url != null && url.startsWith('http')) {
      return CatalogImage(path: url, fit: fit, alignment: alignment);
    }
    final bundled = option.bundledAssetPath;
    if (bundled != null) {
      return CatalogImage(
        path: bundled,
        fit: fit,
        alignment: alignment,
        errorWidget: const Icon(
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
    return CatalogImage(
      path: assetPath,
      fit: BoxFit.fitHeight,
      alignment: Alignment.bottomCenter,
      errorWidget: const Center(
        child: Icon(Icons.person_outlined, color: AppColors.fog, size: 48),
      ),
    );
  }
}
