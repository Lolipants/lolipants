import 'package:flutter/material.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';

/// Cultural region of a traditional style preset.
///
/// Used to pick the region-specific pattern painter (gulf arches, levant
/// zellige, maghreb diamonds) that decorates `RegionStyleButton` tiles.
enum Region { gulf, levant, maghreb, modern }

/// Bundled flat-lay PNG per preset id for Home/Browse thumbnails. Unknown ids
/// fall back to the geometric pattern in `RegionStyleButton`.
const Map<String, String> kRegionPresetPreviewAssetById = {
  'qa_thobe': 'assets/images/designs/design_mens_look_gulf_qatari_thobe_warm_white.png',
  'sa_bisht': 'assets/images/designs/design_mens_look_gulf_sa_bisht_black_gold.png',
  'ae_kandura': 'assets/images/designs/design_mens_look_gulf_ae_kandura_white.png',
  'om_dishdasha': 'assets/images/designs/design_mens_look_gulf_om_dishdasha_green.png',
  'lev_kaftan': 'assets/images/designs/design_womens_look_lev_kaftan_aubergine.png',
  'lev_jubbah': 'assets/images/designs/design_womens_look_lev_jubbah_emerald.png',
  'ma_djellaba': 'assets/images/designs/design_womens_look_mag_djellaba_sage.png',
  'ma_gandoura': 'assets/images/designs/design_womens_look_mag_djellaba_sage.png',
  'mod_minimal': 'assets/images/designs/design_mens_look_mod_thobe_grey_minimal.png',
  'casual_tee':
      'assets/images/designs/design_casual_tee_crew_white.png',
  'casual_polo':
      'assets/images/designs/design_casual_longsleeve_crew_white.png',
  'casual_jumpsuit': 'assets/images/designs/design_womens_look_mod_jumpsuit_green.png',
  'casual_denim': 'assets/images/designs/design_womens_look_mod_dress_denim_indigo.png',
  'casual_coat':
      'assets/images/designs/design_mens_look_mod_mens_overcoat_navy_midnight.png',
  'mens_shirt_ecru':
      'assets/images/designs/design_mens_look_mod_mens_shirt_longline_ecru.png',
  'mens_overshirt_olive':
      'assets/images/designs/design_mens_look_mod_mens_overshirt_olive_linen.png',
  'mens_shacket_camel':
      'assets/images/designs/design_mens_look_mod_mens_shacket_camel.png',
  'mens_hoodie_zip_charcoal':
      'assets/images/designs/design_mens_look_mod_mens_hoodie_zip_charcoal.png',
  'mens_overcoat_navy':
      'assets/images/designs/design_mens_look_mod_mens_overcoat_navy_midnight.png',
  'mens_anorak_sand':
      'assets/images/designs/design_mens_look_mod_mens_anorak_sand.png',
  'mens_cardigan_charcoal':
      'assets/images/designs/design_mens_look_mod_mens_cardigan_long_charcoal.png',
  'mens_trousers_stone':
      'assets/images/designs/design_mens_look_mod_mens_trousers_wide_pleat_stone.png',
  'mens_jacket_sage':
      'assets/images/designs/design_mens_look_mod_mens_jacket_utility_sage.png',
  'mens_polo_black':
      'assets/images/designs/design_mens_look_mod_mens_polo_longline_black.png',
};

Region _regionFromToken(String? token) {
  switch (token?.toLowerCase().trim()) {
    case 'gulf':
      return Region.gulf;
    case 'levant':
      return Region.levant;
    case 'maghreb':
      return Region.maghreb;
    case 'modern':
      return Region.modern;
    default:
      return Region.modern;
  }
}

/// Static preset describing a regional traditional style the customer can
/// launch the editor from.
class RegionStylePreset {
  const RegionStylePreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.region,
    required this.garmentType,
    required this.primaryColour,
    required this.accentColour,
    this.fabricId,
    this.previewAssetPath,
    this.presetType = 'style',
    this.isActive = true,
  });

  factory RegionStylePreset.fromApi(Map<String, dynamic> json) {
    Color parseColor(dynamic value, Color fallback) {
      if (value is int) return Color(value);
      final raw = value?.toString().trim() ?? '';
      if (raw.isEmpty) return fallback;
      final normalized = raw.startsWith('#') ? raw.substring(1) : raw;
      if (normalized.length == 6) {
        return Color(int.parse('FF$normalized', radix: 16));
      }
      if (normalized.length == 8) {
        return Color(int.parse(normalized, radix: 16));
      }
      return fallback;
    }

    String? parsePreviewPath() {
      for (final key in [
        'previewAssetPath',
        'preview_asset_path',
        'image_url',
        'imageUrl',
      ]) {
        final raw = json[key];
        if (raw is String) {
          final t = raw.trim();
          if (t.isNotEmpty) return t;
        }
      }
      return null;
    }

    bool parseBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      if (value is int) return value != 0;
      final raw = value?.toString().trim().toLowerCase() ?? '';
      if (raw == '1' || raw == 'true') return true;
      if (raw == '0' || raw == 'false') return false;
      return fallback;
    }

    final id = json['id']?.toString() ?? '';
    final presetType =
        json['type']?.toString().trim().toLowerCase() ?? 'style';

    return RegionStylePreset(
      id: id,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Preset',
      subtitle: json['subtitle']?.toString() ??
          json['name_ar']?.toString() ??
          '',
      region: _regionFromToken(json['region']?.toString()),
      garmentType: json['garmentType']?.toString() ??
          json['garment_type']?.toString() ??
          'thobe',
      primaryColour: parseColor(
        json['primaryColour'] ?? json['primary_colour'],
        const Color(0xFF14110D),
      ),
      accentColour: parseColor(
        json['accentColour'] ?? json['accent_colour'],
        const Color(0xFFC9A84C),
      ),
      fabricId: json['fabricId']?.toString() ?? json['fabric_id']?.toString(),
      previewAssetPath: parsePreviewPath(),
      presetType: presetType,
      isActive: parseBool(json['is_active'] ?? json['isActive'], true),
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final Region region;
  final String garmentType;
  final Color primaryColour;
  final Color accentColour;
  final String? fabricId;

  /// CMS `type` column: `style`, `casual`, `pattern`, `fabric`, etc.
  final String presetType;

  /// Mirrors API `is_active`; bundled presets default to true.
  final bool isActive;

  /// Optional override from the catalog API; otherwise
  /// [kRegionPresetPreviewAssetById] for legacy bundled ids.
  final String? previewAssetPath;

  /// Shown on Home/Browse grids (excludes pattern/fabric CMS rows).
  bool get showInBrowseCatalog {
    final t = presetType.trim().toLowerCase();
    return t.isEmpty || t == 'style' || t == 'casual';
  }

  /// Casual browse pill and editor casual lane.
  bool get isCasualStyle =>
      presetType == 'casual' ||
      id.startsWith('casual_') ||
      kCasualGarmentTypes.contains(garmentType);

  /// Asset path or URL for list thumbnails; null → geometric fallback.
  String? get resolvedPreviewAssetPath {
    final direct = previewAssetPath;
    if (direct != null && direct.isNotEmpty) return direct;
    return kRegionPresetPreviewAssetById[id];
  }
}

/// Filters API presets for home/browse (active style rows, audience flags).
List<RegionStylePreset> filterPresetCatalog(List<RegionStylePreset> raw) {
  return raw.where((p) {
    if (!p.isActive || !p.showInBrowseCatalog) return false;
    if (!kFeatureMens && kMensCategoryGarmentTypes.contains(p.garmentType)) {
      return false;
    }
    return true;
  }).toList(growable: false);
}

/// Curated list of regional presets shown on Home and Browse
/// (all, filtered by the region pill row).
const List<RegionStylePreset> kRegionPresets = [
  // Gulf
  RegionStylePreset(
    id: 'qa_thobe',
    title: 'Qatari Thobe',
    subtitle: 'Thobe · Bisht · Abaya',
    region: Region.gulf,
    garmentType: 'thobe',
    primaryColour: Color(0xFFF2E9D2),
    accentColour: Color(0xFFC9A84C),
  ),
  RegionStylePreset(
    id: 'sa_bisht',
    title: 'Saudi Bisht',
    subtitle: 'Thobe · Bisht · Kaftan',
    region: Region.gulf,
    garmentType: 'bisht',
    primaryColour: Color(0xFF1F2233),
    accentColour: Color(0xFFC9A14A),
  ),
  RegionStylePreset(
    id: 'ae_kandura',
    title: 'UAE Kandura',
    subtitle: 'Kandura · Abaya',
    region: Region.gulf,
    garmentType: 'kandura',
    primaryColour: Color(0xFFEDE3C8),
    accentColour: Color(0xFFB08D3A),
  ),
  RegionStylePreset(
    id: 'om_dishdasha',
    title: 'Omani Dishdasha',
    subtitle: 'Dishdasha · Kumma',
    region: Region.gulf,
    garmentType: 'dishdasha',
    primaryColour: Color(0xFF1B4A42),
    accentColour: Color(0xFFE2C06A),
  ),
  // Levant
  RegionStylePreset(
    id: 'lev_kaftan',
    title: 'Levant Kaftan',
    subtitle: 'Kaftan · Jubbah',
    region: Region.levant,
    garmentType: 'kaftan',
    primaryColour: Color(0xFF3D2B4F),
    accentColour: Color(0xFFC9A84C),
  ),
  RegionStylePreset(
    id: 'lev_jubbah',
    title: 'Damascene Jubbah',
    subtitle: 'Jubbah · Thobe',
    region: Region.levant,
    garmentType: 'jubbah',
    primaryColour: Color(0xFF1F4D3A),
    accentColour: Color(0xFFE2C06A),
  ),
  // Maghreb
  RegionStylePreset(
    id: 'ma_djellaba',
    title: 'Moroccan Djellaba',
    subtitle: 'Djellaba · Kaftan',
    region: Region.maghreb,
    garmentType: 'djellaba',
    primaryColour: Color(0xFF6B1A1A),
    accentColour: Color(0xFFE2C06A),
  ),
  RegionStylePreset(
    id: 'ma_gandoura',
    title: 'Tunisian Gandoura',
    subtitle: 'Gandoura · Jebba',
    region: Region.maghreb,
    garmentType: 'gandoura',
    primaryColour: Color(0xFF2A3F5F),
    accentColour: Color(0xFFC9A84C),
  ),
  // Modern
  RegionStylePreset(
    id: 'mod_minimal',
    title: 'Modern Minimal',
    subtitle: 'Thobe · Abaya',
    region: Region.modern,
    garmentType: 'thobe',
    primaryColour: Color(0xFF14110D),
    accentColour: Color(0xFFC9A84C),
  ),
  RegionStylePreset(
    id: 'casual_tee',
    title: 'Casual Everyday Tee',
    subtitle: 'T-shirt · print-ready',
    region: Region.modern,
    garmentType: 'tshirt',
    primaryColour: Color(0xFF2A2A2A),
    accentColour: Color(0xFFC9A84C),
  ),
  RegionStylePreset(
    id: 'casual_polo',
    title: 'Relaxed Polo',
    subtitle: 'Polo · weekend',
    region: Region.modern,
    garmentType: 'polo',
    primaryColour: Color(0xFF1E3D2F),
    accentColour: Color(0xFFE2C06A),
  ),
  RegionStylePreset(
    id: 'casual_jumpsuit',
    title: 'Casual Jumpsuit',
    subtitle: 'Jumpsuit · modern',
    region: Region.modern,
    garmentType: 'jumpsuit',
    primaryColour: Color(0xFF1A2E1A),
    accentColour: Color(0xFFC9A84C),
  ),
  RegionStylePreset(
    id: 'casual_denim',
    title: 'Denim Dress',
    subtitle: 'Dress · casual',
    region: Region.modern,
    garmentType: 'dress',
    primaryColour: Color(0xFF1C2742),
    accentColour: Color(0xFFE2C06A),
  ),
  RegionStylePreset(
    id: 'casual_coat',
    title: 'Layered Coat',
    subtitle: 'Coat · street',
    region: Region.modern,
    garmentType: 'coat',
    primaryColour: Color(0xFF222831),
    accentColour: Color(0xFFC9A84C),
  ),
  RegionStylePreset(
    id: 'mens_shirt_ecru',
    title: 'Longline shirt',
    subtitle: 'Men · modern modest',
    region: Region.modern,
    garmentType: 'thobe',
    primaryColour: Color(0xFFEDE6D8),
    accentColour: Color(0xFFC9A84C),
  ),
  RegionStylePreset(
    id: 'mens_overshirt_olive',
    title: 'Linen overshirt',
    subtitle: 'Men · casual office',
    region: Region.modern,
    garmentType: 'thobe',
    primaryColour: Color(0xFF5C6648),
    accentColour: Color(0xFFE2C06A),
  ),
  RegionStylePreset(
    id: 'mens_shacket_camel',
    title: 'Shacket',
    subtitle: 'Men · shirt-jacket',
    region: Region.modern,
    garmentType: 'thobe',
    primaryColour: Color(0xFFC4A574),
    accentColour: Color(0xFF4A3728),
  ),
  RegionStylePreset(
    id: 'mens_hoodie_zip_charcoal',
    title: 'Zip hoodie',
    subtitle: 'Men · longline',
    region: Region.modern,
    garmentType: 'thobe',
    primaryColour: Color(0xFF3A3A3A),
    accentColour: Color(0xFF9E9E9E),
  ),
  RegionStylePreset(
    id: 'mens_overcoat_navy',
    title: 'Slim overcoat',
    subtitle: 'Men · navy',
    region: Region.modern,
    garmentType: 'coat',
    primaryColour: Color(0xFF1A2740),
    accentColour: Color(0xFFC9A84C),
  ),
  RegionStylePreset(
    id: 'mens_anorak_sand',
    title: 'Packable anorak',
    subtitle: 'Men · technical',
    region: Region.modern,
    garmentType: 'coat',
    primaryColour: Color(0xFFD8CBB0),
    accentColour: Color(0xFF6B5B45),
  ),
  RegionStylePreset(
    id: 'mens_cardigan_charcoal',
    title: 'Long cardigan',
    subtitle: 'Men · knit',
    region: Region.modern,
    garmentType: 'thobe',
    primaryColour: Color(0xFF2E2E2E),
    accentColour: Color(0xFFC9A84C),
  ),
  RegionStylePreset(
    id: 'mens_trousers_stone',
    title: 'Wide-leg trousers',
    subtitle: 'Men · pleated',
    region: Region.modern,
    garmentType: 'suit',
    primaryColour: Color(0xFFBFB5A8),
    accentColour: Color(0xFF4A3728),
  ),
  RegionStylePreset(
    id: 'mens_jacket_sage',
    title: 'Utility jacket',
    subtitle: 'Men · field',
    region: Region.modern,
    garmentType: 'coat',
    primaryColour: Color(0xFF7A8F78),
    accentColour: Color(0xFFE2C06A),
  ),
  RegionStylePreset(
    id: 'mens_polo_black',
    title: 'Longline polo',
    subtitle: 'Men · knit',
    region: Region.modern,
    garmentType: 'thobe',
    primaryColour: Color(0xFF141414),
    accentColour: Color(0xFFC9A84C),
  ),
];

/// Garment types aligned with the "Men" browse category
/// (`CategoryDetailScreen` men list).
///
/// When kFeatureMens is false, these are hidden from home/browse style lists.
const Set<String> kMensCategoryGarmentTypes = {
  'thobe',
  'bisht',
  'kandura',
  'dishdasha',
  'jubbah',
  'suit',
  'coat',
};

List<RegionStylePreset> _presetsForAudience() {
  if (kFeatureMens) return kRegionPresets;
  return kRegionPresets
      .where((p) => !kMensCategoryGarmentTypes.contains(p.garmentType))
      .toList(growable: false);
}

/// Home featured grid — first [count] presets from [pool] (API order = newest).
List<RegionStylePreset> regionPresetsForHomeShowcase(
  List<RegionStylePreset> pool, {
  int count = 8,
}) {
  if (pool.isEmpty) return const [];
  return pool.take(count).toList(growable: false);
}

/// First browse pill that has at least one preset in [pool].
String defaultBrowseCatalogPill([List<RegionStylePreset>? pool]) {
  final catalog = pool ?? regionPresetsForHomeGrid();
  const regionOrder = ['gulf', 'levant', 'maghreb', 'modern'];
  for (final name in regionOrder) {
    final r = Region.values.byName(name);
    if (catalog.any((p) => p.region == r)) return name;
  }
  if (kFeatureCasual && catalog.any((p) => p.isCasualStyle)) {
    return 'casual';
  }
  return 'modern';
}

/// Browse hub: [pill] is `gulf`, `levant`, `maghreb`, `modern`, or `casual`.
List<RegionStylePreset> regionPresetsForBrowsePill(
  String pill,
  List<RegionStylePreset> source,
) {
  final key = pill.trim().toLowerCase();
  if (key == 'casual') {
    return source.where((p) => p.isCasualStyle).toList(growable: false);
  }
  final region = Region.values.byName(key);
  return source
      .where((p) => p.region == region)
      .toList(growable: false);
}

/// Filters the preset list by [region], respecting [kFeatureMens].
List<RegionStylePreset> regionPresetsFor(Region region) {
  final out = <RegionStylePreset>[];
  for (final p in _presetsForAudience()) {
    if (p.region == region) out.add(p);
  }
  return out;
}

/// All presets for home grids, respecting [kFeatureMens].
List<RegionStylePreset> regionPresetsForHomeGrid() => _presetsForAudience();
