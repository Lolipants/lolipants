import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Picks a local image for AI body reference (gallery or camera).
///
/// Returns the file path, or null when cancelled or permission denied.
Future<String?> pickCustomMannequinPhoto(
  BuildContext context,
  WidgetRef ref,
) async {
  final locale = ref.read(settingsLocaleProvider);
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(
              localizedFromLocale(
                locale,
                AppStrings.mannequinChooseFromGallery,
                AppStrings.mannequinChooseFromGalleryAr,
              ),
            ),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(
              localizedFromLocale(
                locale,
                AppStrings.mannequinTakePhoto,
                AppStrings.mannequinTakePhotoAr,
              ),
            ),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  final granted = await DevicePermissionPrompt.ensureForImageSource(
    context,
    source,
  );
  if (!granted || !context.mounted) return null;

  final picked = await ImagePicker().pickImage(
    source: source,
    imageQuality: 88,
  );
  return picked?.path;
}
