/// Bundled semi-realistic mannequin bodies under `assets/images/mannequins`.
///
/// Maps stable mannequin **ids** (picker, editor, API fallbacks) to named PNGs:
/// `petite_female.png`, `standard_femal.png`, `athletic_femal.png`,
/// `curvey_femal.png`, `plus_female.png`, `standard_male.png`.
///
/// Legacy ids `tall_male` and `child` remain for older saves. Filenames use
/// `femal` / `curvey` as on disk.
const Map<String, String> kBuiltInMannequinAssets = {
  'petite_female': 'assets/images/mannequins/petite_female.png',
  'standard_female': 'assets/images/mannequins/standard_femal.png',
  'athletic_female': 'assets/images/mannequins/athletic_femal.png',
  'curvy_female': 'assets/images/mannequins/curvey_femal.png',
  'plus_female': 'assets/images/mannequins/plus_female.png',
  'standard_male': 'assets/images/mannequins/standard_male.png',
  'tall_male': 'assets/images/mannequins/standard_male.png',
  'child': 'assets/images/mannequins/petite_female.png',
  // Filename-shaped id aliases (e.g. CMS or hand-edited JSON).
  'standard_femal': 'assets/images/mannequins/standard_femal.png',
  'athletic_femal': 'assets/images/mannequins/athletic_femal.png',
  'curvey_femal': 'assets/images/mannequins/curvey_femal.png',
};

/// Asset path for [mannequinId], or null if none (vector-only silhouette).
String? builtInMannequinAssetPath(String mannequinId) {
  var key = mannequinId.trim().toLowerCase();
  if (key.isEmpty) return null;
  if (key.endsWith('.png')) {
    key = key.substring(0, key.length - 4);
  }
  return kBuiltInMannequinAssets[key];
}
