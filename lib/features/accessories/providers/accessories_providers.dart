import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/accessories/data/accessories_repository.dart';
import 'package:lolipants/features/accessories/data/bundled_accessories.dart';
import 'package:lolipants/features/accessories/models/accessory.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';

final accessoriesRepositoryProvider = Provider<AccessoriesRepository>((ref) {
  return AccessoriesRepository(dio: ref.watch(apiDioProvider));
});

final accessoriesListProvider =
    FutureProvider.family<List<Accessory>, AccessoryCategoryFilter>(
  (ref, filter) async {
    final repo = ref.watch(accessoriesRepositoryProvider);
    final result = await repo.listAccessories(filter: filter);
    return result.fold((_) => filterBundledAccessories(filter), (list) => list);
  },
);

/// Accessories eligible as garment order add-ons.
final addonAccessoriesProvider = FutureProvider<List<Accessory>>((ref) async {
  final all = await ref.watch(accessoriesListProvider(AccessoryCategoryFilter.all).future);
  final addons = all.where((a) => a.allowAddon).toList();
  if (addons.isNotEmpty) return addons;
  return bundledAddonAccessories();
});
