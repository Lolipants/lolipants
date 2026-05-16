import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/catalog_design_picker.dart';

/// Bottom strip: filter chips + horizontal catalogue flats (matches Build UI).
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
    final panelHeight =
        (MediaQuery.sizeOf(context).height * 0.40).clamp(280.0, 380.0);

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
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: state.catalogFilter == DesignCatalogFilter.all,
                      onTap: () =>
                          onCatalogFilterChanged(DesignCatalogFilter.all),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'Traditional',
                      selected: state.catalogFilter ==
                          DesignCatalogFilter.traditional,
                      onTap: () => onCatalogFilterChanged(
                        DesignCatalogFilter.traditional,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'Modern',
                      selected:
                          state.catalogFilter == DesignCatalogFilter.modern,
                      onTap: () =>
                          onCatalogFilterChanged(DesignCatalogFilter.modern),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'Casual',
                      selected:
                          state.catalogFilter == DesignCatalogFilter.casual,
                      onTap: () =>
                          onCatalogFilterChanged(DesignCatalogFilter.casual),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: CatalogDesignPicker(
                sections: sections,
                selectedPath: state.selectedCatalogDesignPath,
                onSelected: onCatalogDesignSelected,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold.withValues(alpha: 0.18) : AppColors.smoke,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: selected ? AppColors.gold : AppColors.fog,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
