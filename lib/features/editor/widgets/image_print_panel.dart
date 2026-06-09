import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/features/editor/utils/picked_image_persist.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/editor/models/print_placement.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Image print controls shown when image tool is selected.
class ImagePrintPanel extends ConsumerWidget {
  const ImagePrintPanel({
    required this.imagePath,
    required this.placement,
    required this.offsetX,
    required this.offsetY,
    required this.scale,
    required this.onImageSelected,
    required this.onPlacementChanged,
    required this.onOffsetXChanged,
    required this.onOffsetYChanged,
    required this.onScaleChanged,
    this.offsetXRange = 60,
    this.offsetYRange = 80,
    this.minScale = 20,
    this.maxScale = 80,
    required this.onApply,
    this.sketchPath,
    this.onSketchSelected,
    super.key,
  });

  final String? imagePath;
  final String? sketchPath;
  final PrintPlacement placement;
  final double offsetX;
  final double offsetY;
  final double scale;
  final ValueChanged<String?> onImageSelected;
  final ValueChanged<String?>? onSketchSelected;
  final ValueChanged<PrintPlacement> onPlacementChanged;
  final ValueChanged<double> onOffsetXChanged;
  final ValueChanged<double> onOffsetYChanged;
  final ValueChanged<double> onScaleChanged;
  final double offsetXRange;
  final double offsetYRange;
  final double minScale;
  final double maxScale;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
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
          Text(
            localizedFromLocale(
              locale,
              AppStrings.editorPrintOnGarment,
              AppStrings.editorPrintOnGarmentAr,
            ),
            style: AppTextStyles.titleMedium,
          ),
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
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.upload_outlined, color: AppColors.gold),
                        const SizedBox(height: 6),
                        Text(
                          localizedFromLocale(
                            locale,
                            AppStrings.editorUploadImage,
                            AppStrings.editorUploadImageAr,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: imagePath!.startsWith('http')
                          ? Image.network(
                              imagePath!,
                              width: 112,
                              height: 112,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(imagePath!),
                              width: 112,
                              height: 112,
                              fit: BoxFit.cover,
                            ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            localizedFromLocale(
              locale,
              AppStrings.editorSketchOptional,
              AppStrings.editorSketchOptionalAr,
            ),
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: onSketchSelected == null ? null : () => _pickSketch(context),
            child: Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: sketchPath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.draw_outlined, color: AppColors.gold),
                        const SizedBox(height: 6),
                        Text(
                          localizedFromLocale(
                            locale,
                            AppStrings.editorUploadSketch,
                            AppStrings.editorUploadSketchAr,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: sketchPath!.startsWith('http')
                          ? Image.network(
                              sketchPath!,
                              width: 112,
                              height: 112,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(sketchPath!),
                              width: 112,
                              height: 112,
                              fit: BoxFit.cover,
                            ),
                    ),
            ),
          ),
          if (onSketchSelected != null && sketchPath != null) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => onSketchSelected!(null),
              child: Text(
                localizedFromLocale(
                  locale,
                  AppStrings.editorSketchClear,
                  AppStrings.editorSketchClearAr,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              _PlacementChip(
                label: localizedFromLocale(
                  locale,
                  AppStrings.editorPrintPlacementChest,
                  AppStrings.editorPrintPlacementChestAr,
                ),
                selected: placement == PrintPlacement.chest,
                onTap: () => onPlacementChanged(PrintPlacement.chest),
              ),
              _PlacementChip(
                label: localizedFromLocale(
                  locale,
                  AppStrings.editorPrintPlacementBack,
                  AppStrings.editorPrintPlacementBackAr,
                ),
                selected: placement == PrintPlacement.back,
                onTap: () => onPlacementChanged(PrintPlacement.back),
              ),
              _PlacementChip(
                label: localizedFromLocale(
                  locale,
                  AppStrings.editorPrintPlacementFullFront,
                  AppStrings.editorPrintPlacementFullFrontAr,
                ),
                selected: placement == PrintPlacement.fullFront,
                onTap: () => onPlacementChanged(PrintPlacement.fullFront),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${localizedFromLocale(locale, AppStrings.editorPrintOffsetHorizontal, AppStrings.editorPrintOffsetHorizontalAr)} ${offsetX.toStringAsFixed(0)}px',
          ),
          Slider(
            value: offsetX.clamp(-offsetXRange, offsetXRange),
            min: -offsetXRange,
            max: offsetXRange,
            divisions: 24,
            onChanged: onOffsetXChanged,
          ),
          Text(
            '${localizedFromLocale(locale, AppStrings.editorPrintOffsetVertical, AppStrings.editorPrintOffsetVerticalAr)} ${offsetY.toStringAsFixed(0)}px',
          ),
          Slider(
            value: offsetY.clamp(-offsetYRange, offsetYRange),
            min: -offsetYRange,
            max: offsetYRange,
            divisions: 32,
            onChanged: onOffsetYChanged,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${localizedFromLocale(locale, AppStrings.editorPrintSizePercent, AppStrings.editorPrintSizePercentAr)} ${scale.toStringAsFixed(0)}%',
          ),
          Slider(
            value: scale.clamp(minScale, maxScale),
            min: minScale,
            max: maxScale,
            divisions: 12,
            onChanged: onScaleChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          LolipantsButton(
            label: localizedFromLocale(
              locale,
              AppStrings.editorApplyToDesign,
              AppStrings.editorApplyToDesignAr,
            ),
            onPressed: onApply,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final granted = await DevicePermissionPrompt.ensureForImageSource(
      context,
      ImageSource.gallery,
    );
    if (!granted) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final path = await persistPickedImage(picked) ?? picked.path;
    onImageSelected(path);
  }

  Future<void> _pickSketch(BuildContext context) async {
    if (onSketchSelected == null) return;
    final granted = await DevicePermissionPrompt.ensureForImageSource(
      context,
      ImageSource.gallery,
    );
    if (!granted) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final path = await persistPickedImage(picked) ?? picked.path;
    onSketchSelected!(path);
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
