import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/catalog_design_picker.dart';

/// Bottom strip: catalogue filter + flat-lay designs (fabric lives in a sheet).
class EditorBottomPanel extends StatelessWidget {
  const EditorBottomPanel({
    required this.state,
    required this.onCatalogDesignSelected,
    required this.onCatalogFilterChanged,
    super.key,
  });

  final EditorState state;
  final ValueChanged<String> onCatalogDesignSelected;
  final ValueChanged<DesignCatalogFilter> onCatalogFilterChanged;

  @override
  Widget build(BuildContext context) {
    final sections = catalogSectionsFor(state.catalogFilter);
    final panelHeight = (MediaQuery.sizeOf(context).height * 0.30)
        .clamp(248.0, 300.0);
    return SizedBox(
      height: panelHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.stone,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          border: const Border(top: BorderSide(color: AppColors.borderStrong)),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              0,
            ),
            child: Text(
              AppStrings.editorTabDesigns,
              style: AppTextStyles.titleSmall.copyWith(color: AppColors.sand),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: state.catalogFilter == DesignCatalogFilter.all,
                    onTap: () =>
                        onCatalogFilterChanged(DesignCatalogFilter.all),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Traditional',
                    selected:
                        state.catalogFilter == DesignCatalogFilter.traditional,
                    onTap: () => onCatalogFilterChanged(
                      DesignCatalogFilter.traditional,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Modern',
                    selected: state.catalogFilter == DesignCatalogFilter.modern,
                    onTap: () =>
                        onCatalogFilterChanged(DesignCatalogFilter.modern),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Casual',
                    selected: state.catalogFilter == DesignCatalogFilter.casual,
                    onTap: () =>
                        onCatalogFilterChanged(DesignCatalogFilter.casual),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          Expanded(
            child: CatalogDesignPicker(
              sections: sections,
              selectedPath: state.selectedCatalogDesignPath,
              onSelected: onCatalogDesignSelected,
              compact: true,
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 12,
          color: selected ? AppColors.ink : AppColors.sand,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.ember,
      side: const BorderSide(color: AppColors.borderSubtle),
    );
  }
}
