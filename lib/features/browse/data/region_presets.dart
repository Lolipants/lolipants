import 'package:flutter/material.dart';
import 'package:lolipants/core/config/app_features.dart';

/// Cultural region of a traditional style preset.
///
/// Used to pick the region-specific pattern painter (gulf arches, levant
/// zellige, maghreb diamonds) that decorates `RegionStyleButton` tiles.
enum Region { gulf, levant, maghreb, modern }

/// Bundled flat-lay PNG per preset id for Home/Browse thumbnails. Unknown ids
/// fall back to the geometric pattern in `RegionStyleButton`.
const Map<String, String> kRegionPresetPreviewAssetById = {
  'qa_thobe': 'assets/images/designs/design_gulf_qatari_thobe_warm_white.png',
  'sa_bisht': 'assets/images/designs/design_gulf_sa_bisht_black_gold.png',
  'ae_kandura': 'assets/images/designs/design_gulf_ae_kandura_white.png',
  'om_dishdasha': 'assets/images/designs/design_gulf_om_dishdasha_green.png',
  'lev_kaftan': 'assets/images/designs/design_lev_kaftan_aubergine.png',
  'lev_jubbah': 'assets/images/designs/design_lev_jubbah_emerald.png',
  'ma_djellaba': 'assets/images/designs/design_mag_djellaba_burgundy_hood.png',
  'ma_gandoura': 'assets/images/designs/design_mag_gandoura_white_grey.png',
  'mod_minimal': 'assets/images/designs/design_mod_thobe_grey_minimal.png',
  'casual_tee':
      'assets/images/designs/design_casual_tee_crew_white.png',
  'casual_polo':
      'assets/images/designs/design_casual_longsleeve_crew_white.png',
  'casual_jumpsuit': 'assets/images/designs/design_mod_jumpsuit_green.png',
  'casual_denim': 'assets/images/designs/design_mod_dress_denim_indigo.png',
  'casual_coat':
      'assets/images/designs/design_mod_mens_overcoat_navy_midnight.png',
  'mens_shirt_ecru':
      'assets/images/designs/design_mod_mens_shirt_longline_ecru.png',
  'mens_overshirt_olive':
      'assets/images/designs/design_mod_mens_overshirt_olive_linen.png',
  'mens_shacket_camel':
      'assets/images/designs/design_mod_mens_shacket_camel.png',
  'mens_hoodie_zip_charcoal':
      'assets/images/designs/design_mod_mens_hoodie_zip_charcoal.png',
  'mens_overcoat_navy':
      'assets/images/designs/design_mod_mens_overcoat_navy_midnight.png',
  'mens_anorak_sand':
      'assets/images/designs/design_mod_mens_anorak_sand.png',
  'mens_cardigan_charcoal':
      'assets/images/designs/design_mod_mens_cardigan_long_charcoal.png',
  'mens_trousers_stone':
      'assets/images/designs/design_mod_mens_trousers_wide_pleat_stone.png',
  'mens_jacket_sage':
      'assets/images/designs/design_mod_mens_jacket_utility_sage.png',
  'mens_polo_black':
      'assets/images/designs/design_mod_mens_polo_longline_black.png',
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
      final raw = json['previewAssetPath'] ?? json['preview_asset_path'];
      if (raw is String) {
        final t = raw.trim();
        if (t.isNotEmpty) return t;
      }
      return null;
    }

    final id = json['id']?.toString() ?? '';

    return RegionStylePreset(
      id: id,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Preset',
      subtitle: json['subtitle']?.toString() ?? '',
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

  /// Optional override from the catalog API; otherwise
  /// [kRegionPresetPreviewAssetById].
  final String? previewAssetPath;

  /// Asset path for list thumbnails, or null to use geometric fallback only.
  String? get resolvedPreviewAssetPath {
    final direct = previewAssetPath;
    if (direct != null && direct.isNotEmpty) return direct;
    return kRegionPresetPreviewAssetById[id];
  }
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

/// Curated grid on Home (Gulf + casual + modern mix).
List<RegionStylePreset> regionPresetsForHomeShowcase() {
  const homeShowcaseCount = 8;
  final pool = _presetsForAudience();
  if (pool.isEmpty) return const [];

  List<String> preferredIds() {
    if (kFeatureMens) {
      return const [
        'mens_anorak_sand',
        'lev_kaftan',
        'qa_thobe',
        'casual_tee',
        'mens_overcoat_navy',
        'sa_bisht',
        'mens_shacket_camel',
        'casual_coat',
      ];
    }
    return const [
      'lev_kaftan',
      'ma_djellaba',
      'casual_tee',
      'casual_denim',
      'sa_bisht',
      'ae_kandura',
      'lev_jubbah',
      'ma_gandoura',
    ];
  }

  final byId = {for (final p in pool) p.id: p};
  final out = <RegionStylePreset>[];
  for (final id in preferredIds()) {
    final p = byId[id];
    if (p != null) out.add(p);
  }
  for (final p in pool) {
    if (out.length >= homeShowcaseCount) break;
    if (!out.any((e) => e.id == p.id)) out.add(p);
  }
  return out.take(homeShowcaseCount).toList(growable: false);
}

/// First browse pill that has at least one preset in the home-grid pool
/// (`regionPresetsForHomeGrid`).
String defaultBrowseCatalogPill() {
  final pool = regionPresetsForHomeGrid();
  const regionOrder = ['gulf', 'levant', 'maghreb', 'modern'];
  for (final name in regionOrder) {
    final r = Region.values.byName(name);
    if (pool.any((p) => p.region == r)) return name;
  }
  if (kFeatureCasual && pool.any((p) => p.id.startsWith('casual_'))) {
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
    return source
        .where((p) => p.id.startsWith('casual_'))
        .toList(growable: false);
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
