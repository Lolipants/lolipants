// Bundled flat-lay design PNGs under `assets/images/designs` (Gemini pipeline).

import 'package:lolipants/features/editor/models/catalog_design_pick.dart';

const String _designsRoot = 'assets/images/designs';

/// Pre-rendered women's catalogue looks (`design_womens_look_*`).
const List<String> kWomenCompleteLookPaths = <String>[
  'assets/images/designs/design_womens_look_blue_azulejo_maxi.png',
  'assets/images/designs/design_womens_look_royal_blue_coral_bishop.png',
  'assets/images/designs/design_womens_look_black_asymmetric_embroidered.png',
  'assets/images/designs/design_womens_look_cream_magenta_paisley.png',
  'assets/images/designs/design_womens_look_blush_beaded_mermaid.png',
  'assets/images/designs/design_womens_look_beige_fringe_embroidery.png',
  'assets/images/designs/design_womens_look_mod_abaya_cape_black.png',
  'assets/images/designs/design_womens_look_mod_abaya_bell_mauve.png',
  'assets/images/designs/design_womens_look_mod_jumpsuit_green.png',
  'assets/images/designs/design_womens_look_mod_abaya_ombre_navy_black.png',
  'assets/images/designs/design_womens_look_mod_abaya_butterfly_white.png',
  'assets/images/designs/design_womens_look_mod_dress_denim_indigo.png',
  'assets/images/designs/design_womens_look_mod_abaya_trench_khaki.png',
  'assets/images/designs/design_womens_look_mod_abaya_athleisure_black.png',
  'assets/images/designs/design_womens_look_mod_abaya_ivory_panels.png',
  'assets/images/designs/design_womens_look_mod_abaya_plum_satin.png',
  'assets/images/designs/design_womens_look_mod_topcoat_navy.png',
  'assets/images/designs/design_womens_look_mod_abaya_powder_blue.png',
  'assets/images/designs/design_womens_look_mod_abaya_colourblock.png',
  'assets/images/designs/design_womens_look_mod_tunic_charcoal_stripe.png',
  'assets/images/designs/design_womens_look_mod_abaya_linen_natural.png',
  'assets/images/designs/design_womens_look_mod_coatdress_camel.png',
  'assets/images/designs/design_womens_look_mag_dress_takchita_inspired.png',
  'assets/images/designs/design_womens_look_lev_dress_crossstitch_abstract.png',
  'assets/images/designs/design_womens_look_mag_djellaba_sage.png',
  'assets/images/designs/design_womens_look_mag_abaya_ivory_lace.png',
  'assets/images/designs/design_womens_look_lev_abaya_wine_silk.png',
  'assets/images/designs/design_womens_look_lev_abaya_jet_gold_trim.png',
  'assets/images/designs/design_womens_look_lev_abaya_charcoal_damask.png',
  'assets/images/designs/design_womens_look_lev_kaftan_aubergine.png',
  'assets/images/designs/design_womens_look_lev_jubbah_emerald.png',
  'assets/images/designs/design_womens_look_gulf_abaya_champagne_guest.png',
  'assets/images/designs/design_womens_look_gulf_abaya_cardigan_charcoal.png',
  'assets/images/designs/design_womens_look_gulf_abaya_navy_champagne.png',
  'assets/images/designs/design_womens_look_gulf_mod_coat_ivory.png',
  'assets/images/designs/design_womens_look_gulf_abaya_sand_rose_trim.png',
  'assets/images/designs/design_womens_look_gulf_abaya_black_closed.png',
];

/// Pre-rendered men's catalogue looks (`design_mens_look_*`).
const List<String> kMenCompleteLookPaths = <String>[
  'assets/images/designs/design_mens_look_mod_mens_polo_longline_black.png',
  'assets/images/designs/design_mens_look_mod_mens_jacket_utility_sage.png',
  'assets/images/designs/design_mens_look_mod_mens_trousers_wide_pleat_stone.png',
  'assets/images/designs/design_mens_look_mod_mens_cardigan_long_charcoal.png',
  'assets/images/designs/design_mens_look_mod_mens_anorak_sand.png',
  'assets/images/designs/design_mens_look_mod_mens_overcoat_navy_midnight.png',
  'assets/images/designs/design_mens_look_mod_mens_hoodie_zip_charcoal.png',
  'assets/images/designs/design_mens_look_mod_mens_shacket_camel.png',
  'assets/images/designs/design_mens_look_mod_mens_overshirt_olive_linen.png',
  'assets/images/designs/design_mens_look_mod_mens_shirt_longline_ecru.png',
  'assets/images/designs/design_mens_look_casual_trousers_slim_black.png',
  'assets/images/designs/design_mens_look_casual_trousers_charcoal_jogger.png',
  'assets/images/designs/design_mens_look_casual_trousers_chino_offwhite.png',
  'assets/images/designs/design_mens_look_lev_thobe_linen_stripe.png',
  'assets/images/designs/design_mens_look_mod_bisht_dove_graphite.png',
  'assets/images/designs/design_mens_look_mod_thobe_grey_minimal.png',
  'assets/images/designs/design_mens_look_gulf_thobe_sky_blue.png',
  'assets/images/designs/design_mens_look_lev_thobe_vest_combo.png',
  'assets/images/designs/design_mens_look_lev_iq_thobe_sand_gold.png',
  'assets/images/designs/design_mens_look_lev_thobe_stone_trim.png',
  'assets/images/designs/design_mens_look_gulf_hijazi_thobe_white.png',
  'assets/images/designs/design_mens_look_gulf_mens_outer_dove.png',
  'assets/images/designs/design_mens_look_gulf_najdi_thobe_winter_white.png',
  'assets/images/designs/design_mens_look_gulf_kw_bisht_chocolate.png',
  'assets/images/designs/design_mens_look_gulf_om_dishdasha_green.png',
  'assets/images/designs/design_mens_look_gulf_ae_kandura_white.png',
  'assets/images/designs/design_mens_look_gulf_sa_bisht_black_gold.png',
  'assets/images/designs/design_mens_look_gulf_qatari_thobe_warm_white.png',
];

/// True when the catalogue PNG already includes a mannequin/model render.
bool isRenderedCatalogLookPath(String path) {
  final p = path.trim().toLowerCase();
  return p.contains('design_womens_look_') || p.contains('design_mens_look_');
}

/// Garment-only flat-lay path for catalogue display (no `_look_` segment).
///
/// Example: `design_womens_look_mag_dress_foo.png` → `design_womens_mag_dress_foo.png`.
/// Casual flat-lays and remote URLs are returned unchanged.
String catalogFlatlayPathFor(String pathOrUrl) {
  final p = pathOrUrl.trim();
  if (p.isEmpty) return p;
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  if (isCmsDesignCatalogRef(p)) return p;
  if (p.contains('design_womens_look_')) {
    return p.replaceFirst('design_womens_look_', 'design_womens_');
  }
  if (p.contains('design_mens_look_')) {
    return p.replaceFirst('design_mens_look_', 'design_mens_');
  }
  return p;
}

/// Legacy `_look_` render used when the flat-lay object is not on CDN yet.
String? catalogLookRenderFallbackPath(String displayPath) {
  final p = displayPath.trim();
  if (p.isEmpty ||
      p.startsWith('http://') ||
      p.startsWith('https://') ||
      isCmsDesignCatalogRef(p)) {
    return null;
  }
  if (isRenderedCatalogLookPath(p)) return null;
  if (p.contains('design_womens_')) {
    return p.replaceFirst('design_womens_', 'design_womens_look_');
  }
  if (p.contains('design_mens_')) {
    return p.replaceFirst('design_mens_', 'design_mens_look_');
  }
  return null;
}

/// Path passed to [CatalogImage] in the design catalogue.
///
/// Uses the bundled `_look_` path that exists on R2 today. When garment-only
/// flat-lays (without `_look_`) are uploaded, [catalogFlatlayPathFor] can be
/// wired in here.
String catalogDesignDisplayPath(String pathOrUrl) {
  final p = pathOrUrl.trim();
  if (p.isEmpty) return p;
  // Prefer flat-lay when the object exists on CDN; otherwise keep bundled look.
  if (p.startsWith('http://') ||
      p.startsWith('https://') ||
      isCmsDesignCatalogRef(p) ||
      isRenderedCatalogLookPath(p) ||
      p.contains('design_casual_')) {
    return p;
  }
  return catalogFlatlayPathFor(p);
}

/// Default design when opening the editor from the mannequin flow.
const String kDefaultCatalogDesignPath =
    '$_designsRoot/design_womens_look_gulf_abaya_black_closed.png';

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

/// Casual lane: unisex flat-lays plus men's trouser looks.
const List<String> kCasualFlatlayPaths = <String>[
  '$_designsRoot/design_casual_tee_crew_white.png',
  '$_designsRoot/design_casual_tee_crew_heather_grey.png',
  '$_designsRoot/design_casual_tee_crew_black.png',
  '$_designsRoot/design_casual_hoodie_pullover_white.png',
  '$_designsRoot/design_casual_hoodie_pullover_heather_grey.png',
  '$_designsRoot/design_casual_hoodie_pullover_black.png',
  '$_designsRoot/design_casual_longsleeve_crew_white.png',
  '$_designsRoot/design_casual_longsleeve_crew_grey_marl.png',
  '$_designsRoot/design_casual_longsleeve_crew_black.png',
  '$_designsRoot/design_mens_look_casual_trousers_chino_offwhite.png',
  '$_designsRoot/design_mens_look_casual_trousers_charcoal_jogger.png',
  '$_designsRoot/design_mens_look_casual_trousers_slim_black.png',
];

const Set<String> _traditionalSectionTitles = {
  'Traditional — Gulf',
  'Levant & Iraq',
  'Maghreb',
};

/// Section title → asset paths (stable order for UI).
/// All paths are bundled PNGs under [assets/images/designs] (mannequin looks
/// or casual flat-lays). Gender filtering hides men's/women's rows per mannequin.
const List<(String sectionTitle, List<String> paths)> kBundledDesignCatalog = [
  (
    'Traditional — Gulf',
    <String>[
      '$_designsRoot/design_womens_look_gulf_abaya_black_closed.png',
      '$_designsRoot/design_womens_look_gulf_abaya_cardigan_charcoal.png',
      '$_designsRoot/design_womens_look_gulf_abaya_champagne_guest.png',
      '$_designsRoot/design_womens_look_gulf_abaya_navy_champagne.png',
      '$_designsRoot/design_womens_look_gulf_abaya_sand_rose_trim.png',
      '$_designsRoot/design_womens_look_gulf_mod_coat_ivory.png',
      '$_designsRoot/design_mens_look_gulf_ae_kandura_white.png',
      '$_designsRoot/design_mens_look_gulf_hijazi_thobe_white.png',
      '$_designsRoot/design_mens_look_gulf_kw_bisht_chocolate.png',
      '$_designsRoot/design_mens_look_gulf_mens_outer_dove.png',
      '$_designsRoot/design_mens_look_gulf_najdi_thobe_winter_white.png',
      '$_designsRoot/design_mens_look_gulf_om_dishdasha_green.png',
      '$_designsRoot/design_mens_look_gulf_qatari_thobe_warm_white.png',
      '$_designsRoot/design_mens_look_gulf_sa_bisht_black_gold.png',
      '$_designsRoot/design_mens_look_gulf_thobe_sky_blue.png',
    ],
  ),
  (
    'Levant & Iraq',
    <String>[
      '$_designsRoot/design_womens_look_lev_abaya_charcoal_damask.png',
      '$_designsRoot/design_womens_look_lev_abaya_jet_gold_trim.png',
      '$_designsRoot/design_womens_look_lev_abaya_wine_silk.png',
      '$_designsRoot/design_womens_look_lev_dress_crossstitch_abstract.png',
      '$_designsRoot/design_womens_look_lev_jubbah_emerald.png',
      '$_designsRoot/design_womens_look_lev_kaftan_aubergine.png',
      '$_designsRoot/design_mens_look_lev_iq_thobe_sand_gold.png',
      '$_designsRoot/design_mens_look_lev_thobe_linen_stripe.png',
      '$_designsRoot/design_mens_look_lev_thobe_stone_trim.png',
      '$_designsRoot/design_mens_look_lev_thobe_vest_combo.png',
    ],
  ),
  (
    'Maghreb',
    <String>[
      '$_designsRoot/design_womens_look_mag_abaya_ivory_lace.png',
      '$_designsRoot/design_womens_look_mag_djellaba_sage.png',
      '$_designsRoot/design_womens_look_mag_dress_takchita_inspired.png',
    ],
  ),
  (
    kCasualDesignCatalogSectionTitle,
    kCasualFlatlayPaths,
  ),
  (
    'Modern',
    <String>[
      '$_designsRoot/design_womens_look_blue_azulejo_maxi.png',
      '$_designsRoot/design_womens_look_royal_blue_coral_bishop.png',
      '$_designsRoot/design_womens_look_black_asymmetric_embroidered.png',
      '$_designsRoot/design_womens_look_cream_magenta_paisley.png',
      '$_designsRoot/design_womens_look_blush_beaded_mermaid.png',
      '$_designsRoot/design_womens_look_beige_fringe_embroidery.png',
      '$_designsRoot/design_womens_look_mod_abaya_cape_black.png',
      '$_designsRoot/design_womens_look_mod_abaya_bell_mauve.png',
      '$_designsRoot/design_womens_look_mod_jumpsuit_green.png',
      '$_designsRoot/design_womens_look_mod_abaya_ombre_navy_black.png',
      '$_designsRoot/design_womens_look_mod_abaya_butterfly_white.png',
      '$_designsRoot/design_womens_look_mod_dress_denim_indigo.png',
      '$_designsRoot/design_womens_look_mod_abaya_trench_khaki.png',
      '$_designsRoot/design_womens_look_mod_abaya_athleisure_black.png',
      '$_designsRoot/design_womens_look_mod_abaya_ivory_panels.png',
      '$_designsRoot/design_womens_look_mod_abaya_plum_satin.png',
      '$_designsRoot/design_womens_look_mod_topcoat_navy.png',
      '$_designsRoot/design_womens_look_mod_abaya_powder_blue.png',
      '$_designsRoot/design_womens_look_mod_abaya_colourblock.png',
      '$_designsRoot/design_womens_look_mod_tunic_charcoal_stripe.png',
      '$_designsRoot/design_womens_look_mod_abaya_linen_natural.png',
      '$_designsRoot/design_womens_look_mod_coatdress_camel.png',
      '$_designsRoot/design_mens_look_mod_bisht_dove_graphite.png',
      '$_designsRoot/design_mens_look_mod_thobe_grey_minimal.png',
      '$_designsRoot/design_mens_look_mod_mens_anorak_sand.png',
      '$_designsRoot/design_mens_look_mod_mens_cardigan_long_charcoal.png',
      '$_designsRoot/design_mens_look_mod_mens_hoodie_zip_charcoal.png',
      '$_designsRoot/design_mens_look_mod_mens_jacket_utility_sage.png',
      '$_designsRoot/design_mens_look_mod_mens_overcoat_navy_midnight.png',
      '$_designsRoot/design_mens_look_mod_mens_overshirt_olive_linen.png',
      '$_designsRoot/design_mens_look_mod_mens_polo_longline_black.png',
      '$_designsRoot/design_mens_look_mod_mens_shacket_camel.png',
      '$_designsRoot/design_mens_look_mod_mens_shirt_longline_ecru.png',
      '$_designsRoot/design_mens_look_mod_mens_trousers_wide_pleat_stone.png',
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

/// Applies [mode] to already-resolved [sections] (e.g. after gender filtering).
List<CatalogDesignSection> filterCatalogSectionsByMode(
  List<CatalogDesignSection> sections,
  DesignCatalogFilter mode,
) {
  if (mode == DesignCatalogFilter.all) return sections;
  final allowedTitles = switch (mode) {
    DesignCatalogFilter.casual => {kCasualDesignCatalogSectionTitle},
    DesignCatalogFilter.traditional => _traditionalSectionTitles,
    DesignCatalogFilter.modern => {'Modern'},
    DesignCatalogFilter.all => null,
  };
  if (allowedTitles == null) return sections;
  return sections
      .where((s) => allowedTitles.contains(s.$1))
      .toList(growable: false);
}

/// UI labels for [DesignCatalogFilter] chips in the design catalogue panel.
String designCatalogFilterLabel(DesignCatalogFilter mode) => switch (mode) {
      DesignCatalogFilter.all => 'All',
      DesignCatalogFilter.traditional => 'Traditional',
      DesignCatalogFilter.modern => 'Modern',
      DesignCatalogFilter.casual => 'Casual',
    };

/// Human-readable label from `assets/.../design_foo_bar.png`.
String catalogDesignLabel(String assetPath) {
  var name = assetPath.split('/').last.replaceAll('.png', '');
  if (name.startsWith('design_')) name = name.substring(7);
  name = name.replaceFirst(RegExp(r'^(womens|mens)_look_'), '');
  return name
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Whether [path] is a casual design (flat-lay or casual look).
bool isCasualCatalogDesignPath(String path) {
  final p = path.trim();
  if (p.isEmpty) return false;
  return kCasualFlatlayPaths.contains(p) ||
      p.contains('design_casual_') ||
      p.contains('_look_casual_');
}

/// Tees, hoodies, and long sleeves — support text/print/colour customization.
bool isCasualBasicFlatlayPath(String path) {
  final p = path.trim().toLowerCase();
  if (p.isEmpty) return false;
  return p.contains('design_casual_tee_') ||
      p.contains('design_casual_hoodie_') ||
      p.contains('design_casual_longsleeve_');
}

/// Casual Designs context: casual asset selected or Casual filter active.
bool isCasualEditorContext({
  required String selectedCatalogDesignPath,
  required DesignCatalogFilter catalogFilter,
}) {
  if (isCasualBasicFlatlayPath(selectedCatalogDesignPath)) return true;
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
  if (p.contains('design_casual_longsleeve_') || p.contains('_longsleeve_')) {
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
