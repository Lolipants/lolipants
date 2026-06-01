import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/browse/providers/preset_providers.dart';
import 'package:lolipants/features/editor/providers/configurator_providers.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/accessories/models/accessory.dart';
import 'package:lolipants/features/accessories/providers/accessories_providers.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';
import 'package:lolipants/features/wedding/providers/wedding_providers.dart';

/// User-facing text for CMS save/delete/upload failures.
String formatAdminCmsError(AppException error, {Locale? locale}) {
  final loc = locale ?? const Locale('en');
  String l(String en, String ar) => localizedFromLocale(loc, en, ar);
  return mapAppExceptionMessage(
    error,
    fallback: l(AdminStrings.cmsSaveFailed, AdminStrings.cmsSaveFailedAr),
    networkMessage: l(AdminStrings.cmsNetworkError, AdminStrings.cmsNetworkErrorAr),
    authMessage: l(AdminStrings.cmsSessionExpired, AdminStrings.cmsSessionExpiredAr),
    statusMessages: {
      400: l(AdminStrings.cmsInvalidFields, AdminStrings.cmsInvalidFieldsAr),
      403: l(AdminStrings.cmsNoPermission, AdminStrings.cmsNoPermissionAr),
      503: l(
        AdminStrings.cmsStorageNotConfigured,
        AdminStrings.cmsStorageNotConfiguredAr,
      ),
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
    case 'accessories':
      ref.invalidate(accessoriesListProvider);
      for (final filter in AccessoryCategoryFilter.values) {
        ref.invalidate(accessoriesListProvider(filter));
      }
      ref.invalidate(addonAccessoriesProvider);
    case 'configurator_templates':
    case 'configurator_slots':
    case 'configurator_options':
      ref.invalidate(configuratorCatalogProvider);
    default:
      break;
  }
}
