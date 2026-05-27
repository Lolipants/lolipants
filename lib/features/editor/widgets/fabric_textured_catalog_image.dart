import 'package:flutter/material.dart';
import 'package:lolipants/features/editor/utils/fabric_texture_overlay.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';

/// Flat-lay catalogue design with optional fabric swatch overlay.
class FabricTexturedCatalogImage extends StatelessWidget {
  const FabricTexturedCatalogImage({
    required this.path,
    required this.fabricProvider,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.errorWidget,
    super.key,
  });

  final String path;
  final ImageProvider? fabricProvider;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final image = CatalogImage(
      path: path,
      fit: fit,
      alignment: alignment,
      errorWidget: errorWidget,
    );

    final fabric = fabricProvider;
    final maskProvider = catalogPathImageProvider(path);
    if (fabric == null || maskProvider == null) return image;

    return FabricTextureOverlay(
      maskImageProvider: maskProvider,
      fabricImageProvider: fabric,
      fit: fit,
      alignment: alignment,
      loadingChild: image,
    );
  }
}
