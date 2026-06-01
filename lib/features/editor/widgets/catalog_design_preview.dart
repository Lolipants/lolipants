import 'package:flutter/material.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';

/// White backdrop shared by catalogue picker thumbs and the hero preview.
const Color kCatalogPreviewBackground = Colors.white;

/// Shared catalogue design renderer used by both the picker thumbnails and the
/// hero preview, so the two never diverge. Wraps [CatalogImage] (R2 with a
/// bundled-asset fallback) on an optional solid backdrop.
class CatalogDesignPreview extends StatelessWidget {
  const CatalogDesignPreview({
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.backgroundColor,
    this.tintColor,
    this.expand = false,
    this.errorWidget,
    super.key,
  });

  /// Asset path or HTTPS URL forwarded to [CatalogImage.path].
  final String imageSource;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Color? backgroundColor;

  /// When set, tints only the garment PNG — not [backgroundColor].
  final Color? tintColor;
  final bool expand;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    Widget buildImage({double? width, double? height}) {
      Widget image = CatalogImage(
        path: imageSource,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        errorWidget: errorWidget,
      );
      final tint = tintColor;
      if (tint != null) {
        image = ColorFiltered(
          colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
          child: image,
        );
      }
      return image;
    }

    final explicitW = width;
    final explicitH = height;

    if (expand) {
      return SizedBox.expand(
        child: ColoredBox(
          color: backgroundColor ?? kCatalogPreviewBackground,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = explicitW ?? constraints.maxWidth;
              final h = explicitH ?? constraints.maxHeight;
              if (!w.isFinite ||
                  !h.isFinite ||
                  w <= 0 ||
                  h <= 0) {
                return const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return buildImage(width: w, height: h);
            },
          ),
        ),
      );
    }

    final Widget content;
    if (explicitW != null && explicitH != null) {
      content = buildImage(width: explicitW, height: explicitH);
    } else {
      content = buildImage();
    }

    if (backgroundColor == null) return content;

    return ColoredBox(
      color: backgroundColor!,
      child: content,
    );
  }
}
