import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/built_in_mannequin_assets.dart';
import 'package:lolipants/features/editor/widgets/configurator_option_image.dart';

/// Local preflight preview for admin catalogue/configurator uploads.
class AdminMannequinAssetPreview extends StatelessWidget {
  const AdminMannequinAssetPreview({
    required this.mannequinId,
    required this.onMannequinChanged,
    required this.onReplace,
    required this.onRemove,
    required this.onConfirmUpload,
    this.mannequins = const [],
    this.stagedFile,
    this.uploadedUrl,
    this.isConfiguratorLayer = false,
    this.uploading = false,
    super.key,
  });

  final XFile? stagedFile;
  final String? uploadedUrl;
  final String mannequinId;
  final ValueChanged<String> onMannequinChanged;
  final VoidCallback onReplace;
  final VoidCallback onRemove;
  final VoidCallback onConfirmUpload;
  final List<AdminPreviewMannequin> mannequins;
  final bool isConfiguratorLayer;
  final bool uploading;

  bool get _hasImage =>
      stagedFile != null ||
      (uploadedUrl != null && uploadedUrl!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    if (!_hasImage) {
      return OutlinedButton.icon(
        onPressed: uploading ? null : onReplace,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Choose image to preview'),
      );
    }

    final options = mannequins.isNotEmpty ? mannequins : _fallbackMannequins;
    final selected = _selectedMannequin(options);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Preview before upload', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Local mannequin preview only. Upload happens after confirmation.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in options)
                  ChoiceChip(
                    label: Text(m.label),
                    selected: selected.id == m.id,
                    onSelected:
                        uploading ? null : (_) => onMannequinChanged(m.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: AppColors.smoke,
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.bottomCenter,
                    children: [
                      if (selected.previewUrl.startsWith('http'))
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: selected.previewUrl,
                            fit: BoxFit.fitHeight,
                            alignment: Alignment.bottomCenter,
                            errorWidget: (_, __, ___) => const Center(
                                child: Icon(Icons.accessibility_new)),
                          ),
                        )
                      else if (selected.previewUrl.isNotEmpty)
                        Positioned.fill(
                          child: EditorMannequinBody(
                              assetPath: selected.previewUrl),
                        )
                      else
                        const Center(child: Icon(Icons.accessibility_new)),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isConfiguratorLayer ? 0 : AppSpacing.xl,
                            vertical: isConfiguratorLayer ? 0 : AppSpacing.md,
                          ),
                          child: _PreviewImage(
                            stagedFile: stagedFile,
                            uploadedUrl: uploadedUrl,
                            fit: isConfiguratorLayer
                                ? BoxFit.fitHeight
                                : BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: uploading ? null : onReplace,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Replace'),
                ),
                if (stagedFile != null)
                  FilledButton.icon(
                    onPressed: uploading ? null : onConfirmUpload,
                    icon: uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(uploading ? 'Uploading...' : 'Confirm upload'),
                  ),
                TextButton.icon(
                  onPressed: uploading ? null : onRemove,
                  icon: const Icon(Icons.close),
                  label: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AdminPreviewMannequin _selectedMannequin(
    List<AdminPreviewMannequin> options,
  ) {
    final canonical = canonicalMannequinIdForApi(mannequinId) ?? mannequinId;
    for (final m in options) {
      if (m.id == mannequinId || m.id == canonical) return m;
    }
    final wantsMale =
        mannequinId.contains('male') && !mannequinId.contains('female');
    for (final m in options) {
      final label = '${m.id} ${m.label}'.toLowerCase();
      final isMale = (label.contains('male') && !label.contains('female')) ||
          label.contains('men');
      if (wantsMale == isMale) return m;
    }
    return options.first;
  }
}

class AdminPreviewMannequin {
  const AdminPreviewMannequin({
    required this.id,
    required this.label,
    required this.previewUrl,
  });

  factory AdminPreviewMannequin.fromCmsRow(Map<String, dynamic> row) {
    final id = row['id']?.toString().trim() ?? '';
    final label = row['label_en']?.toString().trim();
    return AdminPreviewMannequin(
      id: id.isEmpty ? row['label_en']?.toString() ?? 'mannequin' : id,
      label: label != null && label.isNotEmpty ? label : id,
      previewUrl: row['preview_url']?.toString().trim() ?? '',
    );
  }

  final String id;
  final String label;
  final String previewUrl;
}

final List<AdminPreviewMannequin> _fallbackMannequins = [
  for (final m in kVersionMannequinCatalog)
    AdminPreviewMannequin(
      id: m.id,
      label: m.labelEn,
      previewUrl: m.assetPath,
    ),
];

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({
    required this.stagedFile,
    required this.uploadedUrl,
    required this.fit,
  });

  final XFile? stagedFile;
  final String? uploadedUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final file = stagedFile;
    if (file != null) {
      return FutureBuilder(
        future: file.readAsBytes(),
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Image.memory(
            bytes,
            fit: fit,
            alignment: Alignment.bottomCenter,
          );
        },
      );
    }

    final url = uploadedUrl?.trim();
    if (url != null && url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        alignment: Alignment.bottomCenter,
        errorWidget: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }

    return const Center(child: Icon(Icons.image_outlined));
  }
}
