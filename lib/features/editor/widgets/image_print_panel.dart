import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Image print controls shown when image tool is selected.
class ImagePrintPanel extends StatelessWidget {
  const ImagePrintPanel({
    required this.imagePath,
    required this.placement,
    required this.scale,
    required this.onImageSelected,
    required this.onPlacementChanged,
    required this.onScaleChanged,
    super.key,
  });

  final String? imagePath;
  final PrintPlacement placement;
  final double scale;
  final ValueChanged<String?> onImageSelected;
  final ValueChanged<PrintPlacement> onPlacementChanged;
  final ValueChanged<double> onScaleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Print on garment / طباعة على الملبس', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => _pickImage(context),
            child: Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: imagePath == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_outlined, color: AppColors.gold),
                        SizedBox(height: 6),
                        Text('Upload image / ارفع صورة'),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.file(
                        File(imagePath!),
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              _PlacementChip(
                label: 'Chest',
                selected: placement == PrintPlacement.chest,
                onTap: () => onPlacementChanged(PrintPlacement.chest),
              ),
              _PlacementChip(
                label: 'Back',
                selected: placement == PrintPlacement.back,
                onTap: () => onPlacementChanged(PrintPlacement.back),
              ),
              _PlacementChip(
                label: 'Full front',
                selected: placement == PrintPlacement.fullFront,
                onTap: () => onPlacementChanged(PrintPlacement.fullFront),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Size ${scale.toStringAsFixed(0)}%'),
          Slider(
            value: scale.clamp(20, 80),
            min: 20,
            max: 80,
            divisions: 12,
            onChanged: onScaleChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          LolipantsButton(
            label: 'Apply to design',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    onImageSelected(picked.path);
  }
}

class _PlacementChip extends StatelessWidget {
  const _PlacementChip({
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
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
