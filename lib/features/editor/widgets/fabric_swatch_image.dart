import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lolipants/core/assets/catalog_image_uri.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/bundled_fabric_catalog.dart';
import 'package:lolipants/features/editor/models/fabric_option.dart';

/// Renders a fabric swatch from CDN, bundled asset, or colour monogram fallback.
class FabricSwatchImage extends StatelessWidget {
  const FabricSwatchImage({
    required this.fabric,
    required this.fallbackColour,
    super.key,
  });

  final FabricOption fabric;
  final Color fallbackColour;

  @override
  Widget build(BuildContext context) {
    final raw = fabric.swatchUrl.trim().isNotEmpty
        ? fabric.swatchUrl.trim()
        : (bundledFabricSwatchPath(fabric.id) ?? '');
    final assetPath = catalogImageAssetPath(raw);
    final networkUrl = catalogImageNetworkUrl(raw);
    final monogram = fabric.name.isNotEmpty
        ? fabric.name.substring(0, 1).toUpperCase()
        : '?';

    if (assetPath != null) {
      return Padding(
        padding: const EdgeInsets.all(2),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              _MonogramFallback(monogram: monogram, colour: fallbackColour),
        ),
      );
    }
    if (networkUrl != null) {
      return Padding(
        padding: const EdgeInsets.all(2),
        child: CachedNetworkImage(
          imageUrl: networkUrl,
          fit: BoxFit.contain,
          placeholder: (_, __) => ColoredBox(
            color: fallbackColour.withValues(alpha: 0.35),
          ),
          errorWidget: (_, __, ___) =>
              _MonogramFallback(monogram: monogram, colour: fallbackColour),
        ),
      );
    }
    return _MonogramFallback(monogram: monogram, colour: fallbackColour);
  }
}

class _MonogramFallback extends StatelessWidget {
  const _MonogramFallback({required this.monogram, required this.colour});

  final String monogram;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colour,
      child: Center(
        child: Text(
          monogram,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colour.computeLuminance() > 0.55
                ? AppColors.ink
                : Colors.white,
          ),
        ),
      ),
    );
  }
}
