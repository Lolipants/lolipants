/// Semi-realistic mannequin bodies under `assets/images/mannequins`.
///
/// v1 catalogue: four shapes only (2 female, 2 male). Legacy ids from older
/// saves map to the nearest v1 asset.
class BundledMannequinDef {
  const BundledMannequinDef({
    required this.id,
    required this.labelEn,
    required this.labelAr,
    required this.fileName,
    required this.sortOrder,
  });

  final String id;
  final String labelEn;
  final String labelAr;
  final String fileName;
  final int sortOrder;

  String get assetPath => 'assets/images/mannequins/$fileName';
}

/// Active mannequins shown in the picker for this app version.
const List<BundledMannequinDef> kVersionMannequinCatalog = [
  BundledMannequinDef(
    id: 'petite_female',
    labelEn: 'Petite (Female)',
    labelAr: 'نسائي قصير',
    fileName: 'petite_female.png',
    sortOrder: 0,
  ),
  BundledMannequinDef(
    id: 'standard_female',
    labelEn: 'Standard (Female)',
    labelAr: 'نسائي قياسي',
    fileName: 'standard_female.png',
    sortOrder: 1,
  ),
  BundledMannequinDef(
    id: 'standard_male',
    labelEn: 'Standard (Male)',
    labelAr: 'رجالي قياسي',
    fileName: 'standard_male.png',
    sortOrder: 2,
  ),
  BundledMannequinDef(
    id: 'slim_male',
    labelEn: 'Slim (Male)',
    labelAr: 'رجالي نحيف',
    fileName: 'slim_male.png',
    sortOrder: 3,
  ),
];

/// Stable mannequin id → bundled asset path (includes legacy save aliases).
final Map<String, String> kBuiltInMannequinAssets = {
  for (final m in kVersionMannequinCatalog) m.id: m.assetPath,
  // Older saves / CMS ids → nearest v1 body.
  'standard_femal': kVersionMannequinCatalog[1].assetPath,
  'athletic_female': kVersionMannequinCatalog[1].assetPath,
  'athletic_femal': kVersionMannequinCatalog[1].assetPath,
  'curvy_female': kVersionMannequinCatalog[1].assetPath,
  'curvey_femal': kVersionMannequinCatalog[1].assetPath,
  'plus_female': kVersionMannequinCatalog[1].assetPath,
  'tall_male': kVersionMannequinCatalog[2].assetPath,
  'child': kVersionMannequinCatalog[0].assetPath,
};

/// Mannequin used when opening the editor from home/browse preset tiles.
const String kPresetCatalogMannequinId = 'petite_female';

/// All ids treated as local bundled mannequins (no DB row required on save).
const Set<String> kLocalBundledMannequinIds = {
  'petite_female',
  'standard_female',
  'standard_male',
  'slim_male',
  'standard_femal',
  'athletic_female',
  'athletic_femal',
  'curvy_female',
  'curvey_femal',
  'plus_female',
  'tall_male',
  'child',
  'custom_photo',
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
