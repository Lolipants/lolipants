/// Bundled semi-realistic mannequin bodies under [assets/images/mannequins].
///
/// Maps local mannequin id strings to bundled PNGs `M1.png`–`M6.png`.
/// The mannequin picker lists exactly six body ids from `petite_female` through
/// `standard_male`. API may omit `mannequin_id` for these.
/// `tall_male` and `child` remain for legacy saves.
const Map<String, String> kBuiltInMannequinAssets = {
  'petite_female': 'assets/images/mannequins/M1.png',
  'standard_female': 'assets/images/mannequins/M2.png',
  'athletic_female': 'assets/images/mannequins/M3.png',
  'curvy_female': 'assets/images/mannequins/M4.png',
  'plus_female': 'assets/images/mannequins/M5.png',
  'standard_male': 'assets/images/mannequins/M6.png',
  'tall_male': 'assets/images/mannequins/M6.png',
  'child': 'assets/images/mannequins/M1.png',
};

/// Asset path for [mannequinId], or null if none (vector-only silhouette).
String? builtInMannequinAssetPath(String mannequinId) {
  final key = mannequinId.trim().toLowerCase();
  if (key.isEmpty) return null;
  return kBuiltInMannequinAssets[key];
}
