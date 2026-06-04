import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/widgets/featured_design_carousel.dart';
import 'package:lolipants/features/browse/widgets/region_pattern_painter.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';

/// Rounded-rectangle long button used on Home and Browse to open the mannequin
/// picker (same flow as the global design FAB).
///
/// Replaces the earlier 2x2 grids of `StyleCard` / `CountryCard`.
class RegionStyleButton extends StatelessWidget {
  const RegionStyleButton({
    super.key,
    required this.preset,
    this.onTap,
  });

  final RegionStylePreset preset;

  /// Optional override. When null, tapping opens the mannequin selector.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${preset.title}. ${preset.subtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => openDesignMannequinFlow(context, preset: preset),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.stone,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _RegionPatch(preset: preset),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.gold,
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

class _RegionPatch extends StatelessWidget {
  const _RegionPatch({required this.preset});

  final RegionStylePreset preset;

  @override
  Widget build(BuildContext context) {
    final assetPath = preset.resolvedPreviewAssetPath;
    return SizedBox(
      width: 64,
      height: 64,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: assetPath != null
            ? CatalogImage(
                path: assetPath,
                fit: BoxFit.cover,
                width: 64,
                height: 64,
                errorWidget: RegionPresetPatternFallback(preset: preset),
              )
            : RegionPresetPatternFallback(preset: preset),
      ),
    );
  }
}

