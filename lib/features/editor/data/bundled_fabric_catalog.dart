import 'package:lolipants/features/editor/models/fabric_option.dart';

/// Showcase fabric swatches shipped under [kBundledFabricAssetsRoot].
const String kBundledFabricAssetsRoot = 'assets/images/fabrics';

/// Bundled showcase fabrics (10 swatches). Used when the API list is empty or
/// when a row has no remote [FabricOption.swatchUrl].
const List<FabricOption> kBundledShowcaseFabrics = [
  FabricOption(
    id: 'showcase_floral_blue_vintage',
    name: 'Blue vintage floral',
    nameAr: 'زهور كلاسيكية زرقاء',
    quality: 'standard',
    isAvailable: true,
    swatchUrl: '$kBundledFabricAssetsRoot/1.jpeg',
  ),
  FabricOption(
    id: 'showcase_floral_grey_stipple',
    name: 'Grey stipple floral',
    nameAr: 'زهور رمادية منقطة',
    quality: 'standard',
    isAvailable: true,
    swatchUrl: '$kBundledFabricAssetsRoot/2.jpeg',
  ),
  FabricOption(
    id: 'showcase_floral_dark_cottage',
    name: 'Dark cottage floral',
    nameAr: 'زهور داكنة ريفية',
    quality: 'standard',
    isAvailable: true,
    swatchUrl: '$kBundledFabricAssetsRoot/3.jpeg',
  ),
  FabricOption(
    id: 'showcase_floral_brown_ditsy',
    name: 'Brown ditsy floral',
    nameAr: 'زهور بنية صغيرة',
    quality: 'standard',
    isAvailable: true,
    swatchUrl: '$kBundledFabricAssetsRoot/4.jpeg',
  ),
  FabricOption(
    id: 'showcase_floral_black_garden',
    name: 'Black garden floral',
    nameAr: 'زهور سوداء',
    quality: 'standard',
    isAvailable: true,
    swatchUrl: '$kBundledFabricAssetsRoot/5.jpeg',
  ),
  FabricOption(
    id: 'showcase_floral_olive_sketch',
    name: 'Olive sketch floral',
    nameAr: 'زهور زيتونية مرسومة',
    quality: 'standard',
    isAvailable: true,
    swatchUrl: '$kBundledFabricAssetsRoot/6.jpeg',
  ),
  FabricOption(
    id: 'showcase_floral_blue_ditsy',
    name: 'Blue ditsy floral',
    nameAr: 'زهور زرقاء صغيرة',
    quality: 'standard',
    isAvailable: true,
    swatchUrl: '$kBundledFabricAssetsRoot/7.jpeg',
  ),
  FabricOption(
    id: 'showcase_floral_sage_botanical',
    name: 'Sage botanical',
    nameAr: 'نباتات رمادية خضراء',
    quality: 'standard',
    isAvailable: true,
    swatchUrl: '$kBundledFabricAssetsRoot/8.jpeg',
  ),
  FabricOption(
    id: 'showcase_floral_cream_mixed',
    name: 'Cream mixed floral',
    nameAr: 'زهور كريمية متعددة',
    quality: 'standard',
    isAvailable: true,
    swatchUrl: '$kBundledFabricAssetsRoot/9.jpeg',
  ),
  FabricOption(
    id: 'showcase_floral_mauve_dainty',
    name: 'Mauve dainty floral',
    nameAr: 'زهور بنفسجية ناعمة',
    quality: 'standard',
    isAvailable: true,
    swatchUrl: '$kBundledFabricAssetsRoot/10.jpeg',
  ),
];

/// Lookup bundled swatch path by fabric id.
String? bundledFabricSwatchPath(String fabricId) {
  for (final f in kBundledShowcaseFabrics) {
    if (f.id == fabricId) return f.swatchUrl;
  }
  return null;
}

/// Fabrics available for [garmentType] from the bundled catalogue.
List<FabricOption> bundledFabricOptionsForGarment(String garmentType) {
  return kBundledShowcaseFabrics
      .where((f) => f.isAvailable)
      .toList(growable: false);
}

/// Fills missing swatch URLs from the bundled catalogue.
List<FabricOption> enrichFabricSwatches(List<FabricOption> fabrics) {
  if (fabrics.isEmpty) return fabrics;
  final out = <FabricOption>[];
  for (final f in fabrics) {
    if (f.swatchUrl.trim().isNotEmpty) {
      out.add(f);
      continue;
    }
    final bundled = bundledFabricSwatchPath(f.id);
    if (bundled != null && bundled.isNotEmpty) {
      out.add(
        FabricOption(
          id: f.id,
          name: f.name,
          nameAr: f.nameAr,
          quality: f.quality,
          isAvailable: f.isAvailable,
          swatchUrl: bundled,
        ),
      );
    } else {
      out.add(f);
    }
  }
  return out;
}
