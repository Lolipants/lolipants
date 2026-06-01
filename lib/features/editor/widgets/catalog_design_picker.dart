import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/models/catalog_design_pick.dart';
import 'package:lolipants/features/editor/widgets/catalog_design_preview.dart';
import 'package:lolipants/features/editor/widgets/editor_asset_thumb_card.dart';

/// Sectioned horizontal rows of catalogue flats (Build-style white cards).
class CatalogDesignPicker extends StatelessWidget {
  const CatalogDesignPicker({
    required this.sections,
    required this.selectedRef,
    required this.onSelected,
    super.key,
  });

  final List<CatalogDesignSection> sections;
  final String selectedRef;
  final ValueChanged<String> onSelected;

  static const double _cardWidth = 92;
  static const double _cardHeight = 136;
  static const double _rowHeight = 136;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        return Padding(
          padding: EdgeInsets.only(
            bottom: sectionIndex < sections.length - 1 ? AppSpacing.sm : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                section.$1,
                style: AppTextStyles.labelGold.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: _rowHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: section.$2.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final pick = section.$2[i];
                    final selected = pick.ref == selectedRef;
                    return EditorAssetThumbCard(
                      width: _cardWidth,
                      height: _cardHeight,
                      imageScale: 1,
                      imageAlignment: Alignment.center,
                      label: pick.label,
                      selected: selected,
                      onTap: () => onSelected(pick.ref),
                      image: CatalogDesignPreview(
                        imageSource: pick.imageSource,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        backgroundColor: kCatalogPreviewBackground,
                        errorWidget: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 20,
                          color: AppColors.fog,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
