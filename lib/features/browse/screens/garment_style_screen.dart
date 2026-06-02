import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/providers/preset_providers.dart';
import 'package:lolipants/features/browse/widgets/featured_design_carousel.dart';
import 'package:lolipants/features/browse/widgets/region_pattern_painter.dart';
import 'package:lolipants/features/browse/widgets/region_style_button.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Phase 3 `/browse/style/:id` detail screen. Shows the ornament patch for the
/// selected regional preset plus a primary "Design this" CTA that opens the
/// mannequin picker (same flow as the global design FAB).
class GarmentStyleScreen extends ConsumerWidget {
  /// Creates the screen.
  const GarmentStyleScreen({required this.styleId, super.key});

  /// The preset id from the route.
  final String styleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog =
        ref.watch(presetCatalogProvider).valueOrNull ?? regionPresetsForHomeGrid();
    RegionStylePreset? preset;
    for (final candidate in catalog) {
      if (candidate.id == styleId) {
        preset = candidate;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.gold),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/browse');
            }
          },
        ),
        title: Text(
          preset?.title ?? 'Style',
          style: AppTextStyles.titleLarge,
        ),
        backgroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: preset == null
                ? const _UnknownStyle()
                : _StyleDetail(preset: preset, catalog: catalog),
          ),
        ],
      ),
    );
  }
}

class _StyleDetail extends StatelessWidget {
  const _StyleDetail({required this.preset, required this.catalog});

  final RegionStylePreset preset;
  final List<RegionStylePreset> catalog;

  @override
  Widget build(BuildContext context) {
    final variants = catalog
        .where(
          (p) => p.region == preset.region && p.id != preset.id,
        )
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: _StyleHeroImage(preset: preset),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(preset.title, style: AppTextStyles.displayMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            preset.subtitle,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          LolipantsButton(
            label: 'Design this',
            onPressed: () => openDesignMannequinFlow(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (variants.isNotEmpty) ...[
            Text(
              'More ${_regionName(preset.region)} styles',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final variant in variants) ...[
              RegionStyleButton(
                preset: variant,
                onTap: () => context.pushReplacement(
                  '/browse/style/${variant.id}',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ],
      ),
    );
  }

  String _regionName(Region region) {
    switch (region) {
      case Region.gulf:
        return 'Gulf';
      case Region.levant:
        return 'Levant';
      case Region.maghreb:
        return 'Maghreb';
      case Region.modern:
        return 'Modern';
    }
  }
}

class _StyleHeroImage extends StatelessWidget {
  const _StyleHeroImage({required this.preset});

  final RegionStylePreset preset;

  @override
  Widget build(BuildContext context) {
    final assetPath = preset.resolvedPreviewAssetPath;
    if (assetPath == null) {
      return RegionPresetPatternFallback(preset: preset);
    }
    return CatalogImage(
      path: assetPath,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorWidget: RegionPresetPatternFallback(preset: preset),
    );
  }
}

class _UnknownStyle extends StatelessWidget {
  const _UnknownStyle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'This style is no longer available.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}
