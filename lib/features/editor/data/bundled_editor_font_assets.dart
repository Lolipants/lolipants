/// Metadata for custom fonts shipped under [assets/fonts/].
///
/// [family] must match the `family:` entry in [pubspec.yaml].
class BundledEditorFontAsset {
  const BundledEditorFontAsset({
    required this.family,
    required this.label,
    this.previewSample = 'Aa',
    this.isArabic = false,
  });

  final String family;
  final String label;
  final String previewSample;
  final bool isArabic;
}

/// App-shipped display fonts for casual / T-shirt text (excludes Poppins & Naskh).
const List<BundledEditorFontAsset> kBundledEditorFontAssets =
    <BundledEditorFontAsset>[
  BundledEditorFontAsset(family: 'Ashborn', label: 'Ashborn'),
  BundledEditorFontAsset(family: 'Blaugrana', label: 'Blaugrana'),
  BundledEditorFontAsset(family: 'ComicRoasting', label: 'Comic Roast'),
  BundledEditorFontAsset(family: 'Curseyt', label: 'Curseyt'),
  BundledEditorFontAsset(family: 'Dracutaz', label: 'Dracutaz'),
  BundledEditorFontAsset(family: 'Gorecobra', label: 'Gorecobra'),
  BundledEditorFontAsset(family: 'Hellshunx', label: 'Hellshunx'),
  BundledEditorFontAsset(family: 'HigherJump', label: 'Higher Jump'),
  BundledEditorFontAsset(family: 'HoneyBear', label: 'Honey Bear'),
  BundledEditorFontAsset(family: 'Kabisat', label: 'Kabisat'),
  BundledEditorFontAsset(family: 'KatalesBroken', label: 'Katales'),
  BundledEditorFontAsset(family: 'Meltdown', label: 'Meltdown'),
  BundledEditorFontAsset(family: 'MerryBright', label: 'Merry Bright'),
  BundledEditorFontAsset(family: 'Midorima', label: 'Midorima'),
  BundledEditorFontAsset(
    family: 'NoctraDripOutline',
    label: 'Noctra Outline',
  ),
  BundledEditorFontAsset(
    family: 'NoctraDripOutlineMelt',
    label: 'Noctra Melt',
  ),
  BundledEditorFontAsset(family: 'NoctraDripSolid', label: 'Noctra Solid'),
  BundledEditorFontAsset(
    family: 'NoctraDripSolidMelt',
    label: 'Noctra Solid Melt',
  ),
  BundledEditorFontAsset(
    family: 'QomariahArabic',
    label: 'Qomariah',
    previewSample: 'ع',
    isArabic: true,
  ),
  BundledEditorFontAsset(family: 'Redeyes', label: 'Redeyes'),
  BundledEditorFontAsset(family: 'Rockybilly', label: 'Rockybilly'),
  BundledEditorFontAsset(family: 'RollingBeat', label: 'Rolling Beat'),
  BundledEditorFontAsset(family: 'Rooster', label: 'Rooster'),
  BundledEditorFontAsset(family: 'Rusted', label: 'Rusted'),
  BundledEditorFontAsset(family: 'ScholarVarsity', label: 'Scholar'),
  BundledEditorFontAsset(
    family: 'SyamsiahArabic',
    label: 'Syamsiah',
    previewSample: 'ع',
    isArabic: true,
  ),
  BundledEditorFontAsset(family: 'Tottenham1', label: 'Tottenham 1'),
  BundledEditorFontAsset(family: 'Tottenham2', label: 'Tottenham 2'),
  BundledEditorFontAsset(family: 'Tottenham3', label: 'Tottenham 3'),
  BundledEditorFontAsset(family: 'Tottenham4', label: 'Tottenham 4'),
  BundledEditorFontAsset(family: 'Tottenham5', label: 'Tottenham 5'),
  BundledEditorFontAsset(family: 'UrbanStarblues', label: 'Urban Star'),
];
