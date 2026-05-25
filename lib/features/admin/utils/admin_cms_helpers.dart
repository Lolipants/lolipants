import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/features/browse/providers/preset_providers.dart';
import 'package:lolipants/features/editor/providers/configurator_providers.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';
import 'package:lolipants/features/wedding/providers/wedding_providers.dart';

/// User-facing text for CMS save/delete/upload failures.
String formatAdminCmsError(AppException error) {
  return mapAppExceptionMessage(
    error,
    fallback: 'Could not save changes. Please try again.',
    networkMessage: 'Network issue. Check your connection and try again.',
    authMessage: 'Session expired or you do not have CMS access. Sign in again.',
    statusMessages: {
      400: 'Some required fields are missing or invalid.',
      403: 'You do not have permission to change this content.',
      503: 'File storage is not configured on the server.',
    },
  );
}

/// Refreshes public app caches that read CMS-managed content.
void invalidatePublicCmsCache(WidgetRef ref, String resource) {
  switch (resource) {
    case 'design-catalog':
      ref.invalidate(designCatalogItemsProvider);
    case 'presets':
    case 'patterns':
      ref.invalidate(presetCatalogProvider);
    case 'wedding-dresses':
      ref.invalidate(weddingDressesProvider);
      for (final filter in WeddingCategoryFilter.values) {
        ref.invalidate(weddingDressesProvider(filter));
      }
    case 'configurator_templates':
    case 'configurator_slots':
    case 'configurator_options':
      ref.invalidate(configuratorCatalogProvider);
    default:
      break;
  }
}
