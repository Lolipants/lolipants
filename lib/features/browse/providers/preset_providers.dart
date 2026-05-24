import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/data/preset_catalog_repository.dart';
import 'package:lolipants/features/browse/data/preset_gender_filter.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';

final presetCatalogRepositoryProvider = Provider<PresetCatalogRepository>(
  (ref) => PresetCatalogRepository(dio: ref.watch(apiDioProvider)),
);

final presetCatalogProvider = FutureProvider<List<RegionStylePreset>>((ref) async {
  final repo = ref.watch(presetCatalogRepositoryProvider);
  final result = await repo.getPresets();
  return result.fold(
    (_) => regionPresetsForHomeGrid(),
    (presets) {
      final filtered = filterPresetCatalog(presets);
      return filtered.isEmpty ? regionPresetsForHomeGrid() : filtered;
    },
  );
});

/// Home / browse preset pool filtered by the signed-in shopper's gender lane.
final genderFilteredPresetsProvider = Provider<List<RegionStylePreset>>((ref) {
  final gender = ref.watch(userGenderProvider);
  final raw =
      ref.watch(presetCatalogProvider).valueOrNull ?? regionPresetsForHomeGrid();
  return filterPresetsForUserGender(raw, gender);
});
