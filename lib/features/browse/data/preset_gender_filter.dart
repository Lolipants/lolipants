import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';

/// Garment types per browse category slug (shared with category screens).
const Map<String, List<String>> kBrowseCategoryGarmentTypes = {
  'men': ['thobe', 'bisht', 'kandura', 'dishdasha', 'jubbah', 'suit', 'coat'],
  'women': ['abaya', 'kaftan', 'dress', 'jalabiya'],
  'kids': ['dishdasha', 'kandura', 'thobe', 'dress', 'jalabiya'],
};

/// Extra garment types treated as women's when not explicitly men's.
const Set<String> kWomensExtendedGarmentTypes = {
  'djellaba',
  'gandoura',
  'jumpsuit',
};

/// Returns true when [preset] belongs to the men's lane.
bool isMensStylePreset(RegionStylePreset preset) {
  if (preset.id.startsWith('mens_')) return true;
  final men = kBrowseCategoryGarmentTypes[UserGenderPreference.men]!;
  if (men.contains(preset.garmentType)) return true;
  if (preset.isCasualStyle) {
    return preset.garmentType == 'polo' || preset.garmentType == 'tshirt';
  }
  return false;
}

/// Returns true when [preset] belongs to the women's lane.
bool isWomensStylePreset(RegionStylePreset preset) {
  if (preset.id.startsWith('mens_')) return false;
  if (isMensStylePreset(preset)) return false;
  final women = kBrowseCategoryGarmentTypes[UserGenderPreference.women]!;
  if (women.contains(preset.garmentType)) return true;
  if (kWomensExtendedGarmentTypes.contains(preset.garmentType)) return true;
  if (preset.isCasualStyle &&
      (preset.garmentType == 'dress' ||
          preset.garmentType == 'jumpsuit' ||
          preset.id == 'casual_denim')) {
    return true;
  }
  return false;
}

/// Returns true when [preset] belongs to the kids lane.
bool isKidsStylePreset(RegionStylePreset preset) {
  final kids = kBrowseCategoryGarmentTypes[UserGenderPreference.kids]!;
  return kids.contains(preset.garmentType);
}

/// Whether [preset] should appear for the shopper's [gender] lane.
bool presetMatchesUserGender(RegionStylePreset preset, String gender) {
  switch (gender) {
    case UserGenderPreference.men:
      return isMensStylePreset(preset);
    case UserGenderPreference.women:
      return isWomensStylePreset(preset);
    case UserGenderPreference.kids:
      return isKidsStylePreset(preset);
    default:
      return true;
  }
}

/// Filters [presets] to the shopper gender when [gender] is set.
List<RegionStylePreset> filterPresetsForUserGender(
  List<RegionStylePreset> presets,
  String? gender,
) {
  if (gender == null || !UserGenderPreference.all.contains(gender)) {
    return presets;
  }
  return presets
      .where((p) => presetMatchesUserGender(p, gender))
      .toList(growable: false);
}

/// Presets for an explicit browse category slug (men / women / kids / casual).
List<RegionStylePreset> presetsForBrowseCategorySlug(
  String slug,
  List<RegionStylePreset> catalog,
) {
  final key = slug.trim().toLowerCase();
  if (key == 'casual') {
    return catalog.where((p) => p.isCasualStyle).toList(growable: false);
  }
  if (key == UserGenderPreference.men) {
    return catalog.where(isMensStylePreset).toList(growable: false);
  }
  if (key == UserGenderPreference.women) {
    return catalog.where(isWomensStylePreset).toList(growable: false);
  }
  if (key == UserGenderPreference.kids) {
    return catalog.where(isKidsStylePreset).toList(growable: false);
  }
  final garments = kBrowseCategoryGarmentTypes[key];
  if (garments == null || garments.isEmpty) return catalog;
  return catalog
      .where((p) => garments.contains(p.garmentType))
      .toList(growable: false);
}
