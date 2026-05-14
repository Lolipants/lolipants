import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/catalog_design_picker.dart';

/// Bottom strip: catalogue flat designs only (AI prompt lives above).
class EditorBottomPanel extends StatelessWidget {
  const EditorBottomPanel({
    required this.state,
    required this.onCatalogDesignSelected,
    super.key,
  });

  final EditorState state;
  final ValueChanged<String> onCatalogDesignSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
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
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Text(
              AppStrings.editorTabDesigns,
              style: AppTextStyles.titleSmall.copyWith(color: AppColors.sand),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          Expanded(
            child: CatalogDesignPicker(
              selectedPath: state.selectedCatalogDesignPath,
              onSelected: onCatalogDesignSelected,
            ),
          ),
        ],
      ),
    );
  }
}
