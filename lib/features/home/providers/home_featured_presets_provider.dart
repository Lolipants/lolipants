import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/providers/preset_providers.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/home/logic/home_featured_designs.dart';
import 'package:lolipants/features/home/providers/home_flow_provider.dart';

/// Syncs `users.gender` from the API when the home tab is shown.
final homeGenderSyncProvider = FutureProvider<void>((ref) async {
  await ref.read(userGenderProvider.notifier).syncFromApi();
});

/// Profile gender, or in-wizard selection when the shopper has not saved yet.
final effectiveHomeFeaturedGenderProvider = Provider<String?>((ref) {
  final flow = ref.watch(homeFlowSelectionProvider).gender;
  final profile = ref.watch(userGenderProvider);
  return flow ?? profile;
});

/// Featured flat-lay designs for home, filtered by the shopper's gender lane.
final homeFeaturedPresetsProvider = Provider<List<RegionStylePreset>>((ref) {
  ref.watch(homeGenderSyncProvider);
  final gender = ref.watch(effectiveHomeFeaturedGenderProvider);
  if (gender == null) return const [];

  const homeCount = 4;
  final cmsItems =
      ref.watch(designCatalogItemsProvider).valueOrNull ?? const [];
  final featured = buildHomeFeaturedDesigns(
    gender: gender,
    cmsItems: cmsItems,
    count: homeCount,
  );
  if (featured.isNotEmpty) return featured;
  return regionPresetsForHomeShowcase(
    ref.watch(genderFilteredPresetsProvider),
    count: homeCount,
  );
});
