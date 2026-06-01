import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/data/preset_gender_filter.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/providers/preset_providers.dart';

/// Featured presets for home — profile gender lane, never kids.
final homeFeaturedPresetsProvider = Provider<List<RegionStylePreset>>((ref) {
  final gender = ref.watch(userGenderProvider);
  final raw =
      ref.watch(presetCatalogProvider).valueOrNull ?? regionPresetsForHomeGrid();
  final effectiveGender =
      gender == UserGenderPreference.kids ? UserGenderPreference.women : gender;
  final lane = filterPresetsForUserGender(raw, effectiveGender);
  return lane.where((p) => !isKidsStylePreset(p)).toList(growable: false);
});
