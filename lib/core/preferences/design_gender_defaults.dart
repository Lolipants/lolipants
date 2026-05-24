import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/editor/data/built_in_mannequin_assets.dart';

/// Default mannequin for AI / editor entry from a gender lane.
String mannequinIdForGender(String gender) {
  switch (gender) {
    case UserGenderPreference.men:
      return 'standard_male';
    case UserGenderPreference.women:
      return kPresetCatalogMannequinId;
    case UserGenderPreference.kids:
      return 'petite_female';
    default:
      return kPresetCatalogMannequinId;
  }
}

/// Default garment type chip for the home AI designer.
String defaultGarmentTypeForGender(String gender) {
  switch (gender) {
    case UserGenderPreference.men:
      return 'thobe';
    case UserGenderPreference.women:
      return 'abaya';
    default:
      return 'abaya';
  }
}

/// Garment type chips shown in the home AI designer for [gender].
List<(String label, String value)> garmentTypesForGender(String gender) {
  switch (gender) {
    case UserGenderPreference.men:
      return const [
        ('Thobe', 'thobe'),
        ('Dress', 'dress'),
      ];
    case UserGenderPreference.women:
      return const [
        ('Abaya', 'abaya'),
        ('Dress', 'dress'),
      ];
    case UserGenderPreference.kids:
      return const [
        ("Children's", 'jalabiya'),
        ('Dress', 'dress'),
      ];
    default:
      return const [
        ('Abaya', 'abaya'),
        ('Thobe', 'thobe'),
        ('Dress', 'dress'),
      ];
  }
}

/// Quick prompt chips for the home AI designer.
List<String> quickPromptsForGender(String gender) {
  switch (gender) {
    case UserGenderPreference.men:
      return const [
        'Traditional Qatari Thobe with gold trim',
        'Minimalist white Kandura',
        'Modern grey Thobe with subtle embroidery',
      ];
    case UserGenderPreference.women:
      return const [
        'Modern black Abaya with silver embroidery',
        'Elegant navy Abaya with gold trim',
        'Minimalist cream Abaya with delicate lace',
      ];
    case UserGenderPreference.kids:
      return const [
        "Colourful children's Jalabiya",
        'Pastel party dress with soft embroidery',
        'Comfortable cotton play dress',
      ];
    default:
      return const [
        'Traditional Qatari Thobe with gold trim',
        'Modern black Abaya with silver embroidery',
        'Minimalist white Kandura',
      ];
  }
}
