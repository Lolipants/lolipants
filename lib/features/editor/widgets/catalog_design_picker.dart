import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';

/// Sectioned horizontal rows of bundled catalogue design thumbnails.
class CatalogDesignPicker extends StatelessWidget {
  const CatalogDesignPicker({
    super.key,
    required this.selectedPath,
    required this.onSelected,
  });

  final String selectedPath;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      children: [
        Text(
          'Pick a catalogue flat — used with AI and your mannequin.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final section in kBundledDesignCatalog) ...[
          Text(
            section.$1,
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: section.$2.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final path = section.$2[i];
                final sel = path == selectedPath;
                return InkWell(
                  onTap: () => onSelected(path),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: 84,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: sel ? AppColors.gold : AppColors.borderSubtle,
                        width: sel ? 2 : 1,
                      ),
                      color: AppColors.smoke.withValues(alpha: 0.35),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: ColoredBox(
                              color: Colors.white,
                              child: Image.asset(
                                path,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 20,
                                    color: AppColors.fog,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          catalogDesignLabel(path),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 10,
                            color: sel ? AppColors.gold : AppColors.dust,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
