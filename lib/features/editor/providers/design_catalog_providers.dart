import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/data/design_catalog_repository.dart';
import 'package:lolipants/features/editor/logic/catalog_design_gender_filter.dart';
import 'package:lolipants/features/editor/models/catalog_design_pick.dart';
import 'package:lolipants/features/editor/models/design_catalog_item.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';

final designCatalogRepositoryProvider = Provider<DesignCatalogRepository>(
  (ref) => DesignCatalogRepository(dio: ref.watch(apiDioProvider)),
);

/// Active CMS flat-lay designs from `/catalog/designs`.
final designCatalogItemsProvider =
    FutureProvider<List<DesignCatalogItem>>((ref) async {
  final repo = ref.watch(designCatalogRepositoryProvider);
  final result = await repo.fetchActiveItems();
  return result.fold((_) => const [], (items) => items);
});

/// Lookup for resolving `design-catalog:{id}` refs in the editor.
final designCatalogLookupProvider = Provider<Map<String, DesignCatalogItem>>((ref) {
  final items = ref.watch(designCatalogItemsProvider).valueOrNull ?? const [];
  return {for (final item in items) item.id: item};
});

/// Bundled + CMS sections filtered for [mannequinId] (gender lane only).
final mergedCatalogSectionsProvider =
    Provider.family<List<CatalogDesignSection>, String>((ref, mannequinId) {
  final cmsItems = ref.watch(designCatalogItemsProvider).valueOrNull;
  return mergedCatalogSectionsForMannequin(
    mannequinId: mannequinId,
    cmsItems: cmsItems,
  );
});

/// Image source for a catalog ref (bundled path, URL, or CMS lookup).
String resolveCatalogDesignImageSource(
  String ref,
  Map<String, DesignCatalogItem> lookup,
) {
  final id = cmsDesignCatalogId(ref);
  if (id != null) {
    return lookup[id]?.imageUrl ?? '';
  }
  return catalogDesignDisplayPath(ref);
}

/// Display label for a catalog ref.
String resolveCatalogDesignLabel(
  String ref,
  Map<String, DesignCatalogItem> lookup,
) {
  final id = cmsDesignCatalogId(ref);
  if (id != null) {
    final label = lookup[id]?.labelEn ?? '';
    if (label.isNotEmpty) return label;
  }
  return catalogDesignLabel(ref);
}
