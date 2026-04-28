import 'package:flutter/material.dart';
import 'package:lolipants/core/config/app_features.dart';

/// Cultural region of a traditional style preset.
///
/// Used to pick the region-specific pattern painter (gulf arches, levant
/// zellige, maghreb diamonds) that decorates [RegionStyleButton] tiles.
enum Region { gulf, levant, maghreb, modern }

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
  });

  final String id;
  final String title;
  final String subtitle;
  final Region region;
  final String garmentType;
  final Color primaryColour;
  final Color accentColour;
  final String? fabricId;

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

    return RegionStylePreset(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Preset',
      subtitle: json['subtitle']?.toString() ?? '',
      region: _regionFromToken(json['region']?.toString()),
      garmentType: json['garmentType']?.toString() ??
          json['garment_type']?.toString() ??
          'thobe',
      primaryColour: parseColor(json['primaryColour'] ?? json['primary_colour'], const Color(0xFF14110D)),
      accentColour: parseColor(json['accentColour'] ?? json['accent_colour'], const Color(0xFFC9A84C)),
      fabricId: json['fabricId']?.toString() ?? json['fabric_id']?.toString(),
    );
  }
}

/// Curated list of regional presets shown on Home (first 4) and Browse
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
];

/// Garment types aligned with the "Men" browse category
/// ([CategoryDetailScreen._categoryGarments]).
///
/// When [kFeatureMens] is false, these are hidden from home/browse style lists.
const Set<String> kMensCategoryGarmentTypes = {
  'thobe',
  'bisht',
  'kandura',
  'dishdasha',
  'jubbah',
  'suit',
};

List<RegionStylePreset> _presetsForAudience() {
  if (kFeatureMens) return kRegionPresets;
  return kRegionPresets
      .where((p) => !kMensCategoryGarmentTypes.contains(p.garmentType))
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
