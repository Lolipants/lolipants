// Bundled flat-lay design PNGs under `assets/images/designs` (Gemini pipeline).

import 'package:lolipants/features/editor/models/catalog_design_pick.dart';

/// Default design when opening the editor from the mannequin flow.
const String kDefaultCatalogDesignPath =
    'assets/images/designs/design_gulf_abaya_black_closed.png';

/// Garment types that use the Casual catalogue lane and casual-first QA flows.
const Set<String> kCasualGarmentTypes = {
  'tshirt',
  'polo',
  'jumpsuit',
  'hoodie',
  'longsleeve',
  'trousers',
};

/// Catalogue subsection for the editor Designs strip.
enum DesignCatalogFilter {
  /// Gulf, Levant, Maghreb, Casual basics, Modern (`design_mod_*`).
  all,

  /// Gulf, Levant, Maghreb only.
  traditional,

  /// `design_casual_*` flat-lays (tees, hoodies, long sleeves, trousers).
  casual,

  /// Modern modest pieces (`design_mod_*` only).
  modern,
}

/// Section title for [kCasualFlatlayPaths] in [kBundledDesignCatalog] and the
/// **Casual** filter.
const String kCasualDesignCatalogSectionTitle =
    'Casual — Tees, hoodies & trousers';

/// Flat-lays when **Casual** is selected (`design_casual_*`).
/// `design_mod_*` pieces live only under **Modern** — see that list.
const List<String> kCasualFlatlayPaths = <String>[
  'assets/images/designs/design_casual_tee_crew_white.png',
  'assets/images/designs/design_casual_tee_crew_heather_grey.png',
  'assets/images/designs/design_casual_tee_crew_black.png',
  'assets/images/designs/design_casual_hoodie_pullover_white.png',
  'assets/images/designs/design_casual_hoodie_pullover_heather_grey.png',
  'assets/images/designs/design_casual_hoodie_pullover_black.png',
  'assets/images/designs/design_casual_longsleeve_crew_white.png',
  'assets/images/designs/design_casual_longsleeve_crew_grey_marl.png',
  'assets/images/designs/design_casual_longsleeve_crew_black.png',
  'assets/images/designs/design_casual_trousers_chino_offwhite.png',
  'assets/images/designs/design_casual_trousers_charcoal_jogger.png',
  'assets/images/designs/design_casual_trousers_slim_black.png',
];

const Set<String> _traditionalSectionTitles = {
  'Traditional — Gulf',
  'Levant & Iraq',
  'Maghreb',
};

/// Section title → asset paths (stable order for UI).
const List<(String sectionTitle, List<String> paths)> kBundledDesignCatalog = [
  (
    'Traditional — Gulf',
    <String>[
      'assets/images/designs/design_gulf_abaya_black_closed.png',
      'assets/images/designs/design_gulf_abaya_cardigan_charcoal.png',
      'assets/images/designs/design_gulf_abaya_champagne_guest.png',
      'assets/images/designs/design_gulf_abaya_navy_champagne.png',
      'assets/images/designs/design_gulf_abaya_sand_rose_trim.png',
      'assets/images/designs/design_gulf_ae_kandura_white.png',
      'assets/images/designs/design_gulf_bh_thobe_pearl_grey.png',
      'assets/images/designs/design_gulf_hijazi_thobe_white.png',
      'assets/images/designs/design_gulf_kw_bisht_chocolate.png',
      'assets/images/designs/design_gulf_mens_outer_dove.png',
      'assets/images/designs/design_gulf_mod_coat_ivory.png',
      'assets/images/designs/design_gulf_najdi_thobe_winter_white.png',
      'assets/images/designs/design_gulf_om_dishdasha_green.png',
      'assets/images/designs/design_gulf_qatari_thobe_warm_white.png',
      'assets/images/designs/design_gulf_sa_bisht_black_gold.png',
      'assets/images/designs/design_gulf_thobe_sky_blue.png',
    ],
  ),
  (
    'Levant & Iraq',
    <String>[
      'assets/images/designs/design_lev_abaya_charcoal_damask.png',
      'assets/images/designs/design_lev_abaya_jet_gold_trim.png',
      'assets/images/designs/design_lev_abaya_wine_silk.png',
      'assets/images/designs/design_lev_dress_crossstitch_abstract.png',
      'assets/images/designs/design_lev_iq_thobe_sand_gold.png',
      'assets/images/designs/design_lev_jubbah_emerald.png',
      'assets/images/designs/design_lev_kaftan_aubergine.png',
      'assets/images/designs/design_lev_thobe_linen_stripe.png',
      'assets/images/designs/design_lev_thobe_stone_trim.png',
      'assets/images/designs/design_lev_thobe_vest_combo.png',
    ],
  ),
  (
    'Maghreb',
    <String>[
      'assets/images/designs/design_mag_abaya_ivory_lace.png',
      'assets/images/designs/design_mag_caftan_olive.png',
      'assets/images/designs/design_mag_cloak_rust_cream.png',
      'assets/images/designs/design_mag_djellaba_burgundy_hood.png',
      'assets/images/designs/design_mag_djellaba_sage.png',
      'assets/images/designs/design_mag_dress_takchita_inspired.png',
      'assets/images/designs/design_mag_gandoura_indigo.png',
      'assets/images/designs/design_mag_gandoura_white_grey.png',
    ],
  ),
  (
    kCasualDesignCatalogSectionTitle,
    kCasualFlatlayPaths,
  ),
  (
    'Modern',
    <String>[
      'assets/images/designs/design_mod_abaya_athleisure_black.png',
      'assets/images/designs/design_mod_abaya_bell_mauve.png',
      'assets/images/designs/design_mod_abaya_black_arch.png',
      'assets/images/designs/design_mod_abaya_butterfly_white.png',
      'assets/images/designs/design_mod_abaya_cape_black.png',
      'assets/images/designs/design_mod_abaya_colourblock.png',
      'assets/images/designs/design_mod_abaya_ivory_panels.png',
      'assets/images/designs/design_mod_abaya_linen_natural.png',
      'assets/images/designs/design_mod_abaya_ombre_navy_black.png',
      'assets/images/designs/design_mod_abaya_plum_satin.png',
      'assets/images/designs/design_mod_abaya_powder_blue.png',
      'assets/images/designs/design_mod_abaya_slate_tech.png',
      'assets/images/designs/design_mod_abaya_trench_khaki.png',
      'assets/images/designs/design_mod_bisht_dove_graphite.png',
      'assets/images/designs/design_mod_thobe_grey_minimal.png',
      'assets/images/designs/design_mod_tunic_charcoal_stripe.png',
      'assets/images/designs/design_mod_jumpsuit_green.png',
      'assets/images/designs/design_mod_dress_denim_indigo.png',
      'assets/images/designs/design_mod_topcoat_navy.png',
      'assets/images/designs/design_mod_coatdress_camel.png',
      'assets/images/designs/design_mod_mens_shirt_longline_ecru.png',
      'assets/images/designs/design_mod_mens_overshirt_olive_linen.png',
      'assets/images/designs/design_mod_mens_shacket_camel.png',
      'assets/images/designs/design_mod_mens_hoodie_zip_charcoal.png',
      'assets/images/designs/design_mod_mens_overcoat_navy_midnight.png',
      'assets/images/designs/design_mod_mens_anorak_sand.png',
      'assets/images/designs/design_mod_mens_cardigan_long_charcoal.png',
      'assets/images/designs/design_mod_mens_trousers_wide_pleat_stone.png',
      'assets/images/designs/design_mod_mens_jacket_utility_sage.png',
      'assets/images/designs/design_mod_mens_polo_longline_black.png',
    ],
  ),
];

/// Subset of [kBundledDesignCatalog] for the editor filter control.
List<(String sectionTitle, List<String> paths)> catalogSectionsFor(
  DesignCatalogFilter mode,
) {
  switch (mode) {
    case DesignCatalogFilter.all:
      return kBundledDesignCatalog;
    case DesignCatalogFilter.casual:
      return kBundledDesignCatalog
          .where((s) => s.$1 == kCasualDesignCatalogSectionTitle)
          .toList(growable: false);
    case DesignCatalogFilter.traditional:
      return kBundledDesignCatalog
          .where((s) => _traditionalSectionTitles.contains(s.$1))
          .toList(growable: false);
    case DesignCatalogFilter.modern:
      return kBundledDesignCatalog
          .where((s) => s.$1 == 'Modern')
          .toList(growable: false);
  }
}

/// Human-readable label from `assets/.../design_foo_bar.png`.
String catalogDesignLabel(String assetPath) {
  final name = assetPath.split('/').last.replaceAll('.png', '');
  final core = name.startsWith('design_') ? name.substring(7) : name;
  return core
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Whether [path] is a casual flat-lay (`design_casual_*` or listed in [kCasualFlatlayPaths]).
bool isCasualCatalogDesignPath(String path) {
  final p = path.trim();
  if (p.isEmpty) return false;
  return kCasualFlatlayPaths.contains(p) || p.contains('design_casual_');
}

/// Casual Designs context: casual asset selected or Casual filter active.
bool isCasualEditorContext({
  required String selectedCatalogDesignPath,
  required DesignCatalogFilter catalogFilter,
}) {
  if (isCasualCatalogDesignPath(selectedCatalogDesignPath)) return true;
  return catalogFilter == DesignCatalogFilter.casual;
}

/// Default garment type when editing casual catalogue flats.
const String kDefaultCasualGarmentType = 'tshirt';

/// Maps a casual flat-lay asset path to the garment type stored on save.
String garmentTypeFromCatalogDesignPath(String assetPath) {
  final p = assetPath.trim().toLowerCase();
  if (p.isEmpty) return kDefaultCasualGarmentType;
  if (p.contains('design_casual_tee_') || p.contains('_tee_')) {
    return 'tshirt';
  }
  if (p.contains('design_casual_hoodie_') || p.contains('_hoodie_')) {
    return 'hoodie';
  }
  if (p.contains('design_casual_longsleeve_') ||
      p.contains('_longsleeve_')) {
    return 'longsleeve';
  }
  if (p.contains('design_casual_trousers_') || p.contains('_trousers_')) {
    return 'trousers';
  }
  if (p.contains('design_casual_polo_') || p.contains('_polo_')) {
    return 'polo';
  }
  if (p.contains('design_casual_jumpsuit_') || p.contains('_jumpsuit_')) {
    return 'jumpsuit';
  }
  if (isCasualCatalogDesignPath(assetPath)) {
    return kDefaultCasualGarmentType;
  }
  return kDefaultCasualGarmentType;
}

/// Returns bundled catalogue asset path or CMS ref from API `render_metadata`.
String? catalogDesignAssetFromRenderMetadata(
  Map<String, dynamic>? renderMetadata,
) {
  if (renderMetadata == null) return null;
  final raw = renderMetadata['selectedCatalogDesignPath'];
  if (raw is! String) return null;
  final p = raw.trim();
  if (p.isEmpty) return null;
  if (isCmsDesignCatalogRef(p)) return p;
  if (!p.startsWith('assets/images/designs/')) return null;
  return p;
}
