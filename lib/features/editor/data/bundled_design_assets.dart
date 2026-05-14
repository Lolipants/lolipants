// Bundled flat-lay design PNGs under `assets/images/designs` (Gemini pipeline).

/// Default design when opening the editor from the mannequin flow.
const String kDefaultCatalogDesignPath =
    'assets/images/designs/design_gulf_abaya_black_closed.png';

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
      'assets/images/designs/design_mod_coatdress_camel.png',
      'assets/images/designs/design_mod_dress_denim_indigo.png',
      'assets/images/designs/design_mod_jumpsuit_green.png',
      'assets/images/designs/design_mod_thobe_grey_minimal.png',
      'assets/images/designs/design_mod_topcoat_navy.png',
      'assets/images/designs/design_mod_tunic_charcoal_stripe.png',
    ],
  ),
];

/// Human-readable label from `assets/.../design_foo_bar.png`.
String catalogDesignLabel(String assetPath) {
  final name = assetPath.split('/').last.replaceAll('.png', '');
  final core = name.startsWith('design_') ? name.substring(7) : name;
  return core
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Returns bundled catalogue asset path from API `render_metadata`, or null.
String? catalogDesignAssetFromRenderMetadata(
  Map<String, dynamic>? renderMetadata,
) {
  if (renderMetadata == null) return null;
  final raw = renderMetadata['selectedCatalogDesignPath'];
  if (raw is! String) return null;
  final p = raw.trim();
  if (p.isEmpty) return null;
  if (!p.startsWith('assets/images/designs/')) return null;
  return p;
}
