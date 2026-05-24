import 'package:flutter/material.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';

/// Renders a bundled mannequin PNG.
///
/// Use [BoxFit.contain] in picker thumbnails; [BoxFit.fitHeight] in the editor
/// hero so garment layers (also fitHeight) stay aligned on the body.
class BundledMannequinImage extends StatelessWidget {
  const BundledMannequinImage({
    required this.assetPath,
    this.fit = BoxFit.contain,
    super.key,
  });

  final String assetPath;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CatalogImage(
      path: assetPath,
      fit: fit,
      alignment: Alignment.bottomCenter,
    );
  }
}
