import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';

/// Sectioned horizontal rows of bundled catalogue design thumbnails.
class CatalogDesignPicker extends StatelessWidget {
  const CatalogDesignPicker({
    super.key,
    required this.sections,
    required this.selectedPath,
    required this.onSelected,
    this.compact = false,
  });

  /// Usually from [catalogSectionsFor]; may be a filtered view.
  final List<(String sectionTitle, List<String> paths)> sections;

  final String selectedPath;
  final ValueChanged<String> onSelected;

  /// Tighter rows and copy for the editor bottom sheet.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rowH = compact ? 88.0 : 108.0;
    final thumbW = compact ? 72.0 : 84.0;
    final labelSize = compact ? 9.0 : 10.0;
    final sectionStyle = AppTextStyles.titleSmall.copyWith(
      color: AppColors.gold,
      fontSize: compact ? 12 : null,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        compact ? 6 : AppSpacing.sm,
        AppSpacing.md,
        compact ? AppSpacing.sm : AppSpacing.md,
      ),
      children: [
        Text(
          compact
              ? 'Catalogue flats'
              : 'Pick a catalogue flat — used with AI and your mannequin.',
          maxLines: compact ? 1 : 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.fog,
            fontSize: compact ? 11 : null,
          ),
        ),
        SizedBox(height: compact ? 4 : AppSpacing.sm),
        for (final section in sections) ...[
          Text(
            section.$1,
            style: sectionStyle,
          ),
          SizedBox(height: compact ? 2 : AppSpacing.xs),
          SizedBox(
            height: rowH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: section.$2.length,
              separatorBuilder: (_, __) =>
                  SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
              itemBuilder: (context, i) {
                final path = section.$2[i];
                final sel = path == selectedPath;
                return InkWell(
                  onTap: () => onSelected(path),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: thumbW,
                    padding: EdgeInsets.all(compact ? 3 : 4),
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
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: compact ? 16 : 20,
                                    color: AppColors.fog,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 2 : 4),
                        Text(
                          catalogDesignLabel(path),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: labelSize,
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
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        ],
      ],
    );
  }
}
