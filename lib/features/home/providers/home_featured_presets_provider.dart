import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/providers/preset_providers.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/home/logic/home_featured_designs.dart';

/// Syncs `users.gender` from the API when the home tab is shown.
final homeGenderSyncProvider = FutureProvider<void>((ref) async {
  await ref.read(userGenderProvider.notifier).syncFromApi();
});

/// Featured flat-lay designs for home, filtered by the signed-in user's gender.
final homeFeaturedPresetsProvider = Provider<List<RegionStylePreset>>((ref) {
  ref.watch(homeGenderSyncProvider);
  final gender = ref.watch(userGenderProvider);
  final cmsItems =
      ref.watch(designCatalogItemsProvider).valueOrNull ?? const [];
  final featured = buildHomeFeaturedDesigns(
    gender: gender,
    cmsItems: cmsItems,
  );
  if (featured.isNotEmpty) return featured;
  return regionPresetsForHomeShowcase(ref.watch(genderFilteredPresetsProvider));
});
