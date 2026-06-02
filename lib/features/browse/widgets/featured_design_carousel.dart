import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/widgets/region_pattern_painter.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';

/// Same entry as the global design FAB — choose a mannequin before the editor.
void openDesignMannequinFlow(BuildContext context) {
  context.push('/mannequin-selector');
}

/// Featured designs — frosted-glass tiles in a vertical two-column grid.
class FeaturedDesignsSection extends StatelessWidget {
  const FeaturedDesignsSection({
    required this.presets,
    this.onSeeAll,
    this.showHeader = true,
    this.fillHeight = false,
    super.key,
  });

  final List<RegionStylePreset> presets;
  final VoidCallback? onSeeAll;
  final bool showHeader;

  /// Expands the grid to fill remaining height (requires a bounded parent).
  final bool fillHeight;

  static const double tileWidth = 152;
  static const double tileHeight = 212;
  static const double _gap = 14;

  @override
  Widget build(BuildContext context) {
    if (presets.isEmpty) return const SizedBox.shrink();

    final tiles = GridView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: _gap,
        crossAxisSpacing: _gap,
        childAspectRatio: tileWidth / tileHeight,
      ),
      itemCount: presets.length,
      itemBuilder: (context, index) => FeaturedDesignTile(
        preset: presets[index],
        width: tileWidth,
        height: tileHeight,
        expandToConstraints: true,
      ),
    );

    final scrollable = fillHeight ? Expanded(child: tiles) : tiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize:
          fillHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (showHeader) ...[
          _SectionHeader(onSeeAll: onSeeAll),
          const SizedBox(height: AppSpacing.lg),
        ],
        scrollable,
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({this.onSeeAll});

  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            AppStrings.sectionFeaturedDesigns,
            style: AppTextStyles.titleMedium.copyWith(
              letterSpacing: 0.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppStrings.seeAll,
              style: AppTextStyles.labelGold.copyWith(
                fontSize: 12,
                letterSpacing: 0.4,
              ),
            ),
          ),
      ],
    );
  }
}

/// Single portrait tile in the featured carousel.
class FeaturedDesignTile extends StatelessWidget {
  const FeaturedDesignTile({
    required this.preset,
    this.width = FeaturedDesignsSection.tileWidth,
    this.height = FeaturedDesignsSection.tileHeight,
    this.expandToConstraints = false,
    super.key,
  });

  final RegionStylePreset preset;
  final double width;
  final double height;
  final bool expandToConstraints;

  @override
  Widget build(BuildContext context) {
    if (!expandToConstraints) {
      return _FeaturedDesignTileBody(
        preset: preset,
        width: width,
        height: height,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => _FeaturedDesignTileBody(
        preset: preset,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
      ),
    );
  }
}

class _FeaturedDesignTileBody extends StatelessWidget {
  const _FeaturedDesignTileBody({
    required this.preset,
    required this.width,
    required this.height,
  });

  final RegionStylePreset preset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: preset.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openDesignMannequinFlow(context),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _FrostedGlassFill(),
                  _PreviewImage(preset: preset),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.55, 1],
                        colors: [
                          Colors.transparent,
                          AppColors.ink.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: _RegionChip(region: preset.region),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Text(
                      preset.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.sand,
                        height: 1.15,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Blurred, translucent card surface so the arabesque shows through.
class _FrostedGlassFill extends StatelessWidget {
  const _FrostedGlassFill();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.03),
            ],
          ),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.28),
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.preset});

  final RegionStylePreset preset;

  /// Inset so the flat-lay reads smaller inside the fixed card frame.
  static const EdgeInsets _garmentPadding = EdgeInsets.fromLTRB(
    20,
    28,
    20,
    48,
  );

  @override
  Widget build(BuildContext context) {
    final assetPath = preset.resolvedPreviewAssetPath;
    final child = assetPath == null
        ? Opacity(
            opacity: 0.88,
            child: RegionPresetPatternFallback(preset: preset),
          )
        : CatalogImage(
            path: assetPath,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorWidget: RegionPresetPatternFallback(preset: preset),
          );

    return Padding(
      padding: _garmentPadding,
      child: child,
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({required this.region});

  final Region region;

  String get _label => switch (region) {
        Region.gulf => 'Gulf',
        Region.levant => 'Levant',
        Region.maghreb => 'Maghreb',
        Region.modern => 'Modern',
      };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            _label,
            style: AppTextStyles.labelGold.copyWith(
              fontSize: 9,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
