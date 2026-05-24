import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/data/preset_gender_filter.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/logic/mannequin_gender.dart';

/// Infers garment lane from a flat-lay asset file name.
String? garmentTypeFromCatalogDesignPathName(String path) {
  final p = path.trim().toLowerCase();
  if (p.contains('design_mod_mens_') || p.contains('_mens_')) return 'coat';
  if (p.contains('abaya')) return 'abaya';
  if (p.contains('kaftan') || p.contains('caftan')) return 'kaftan';
  if (p.contains('dress')) return 'dress';
  if (p.contains('djellaba')) return 'djellaba';
  if (p.contains('gandoura')) return 'gandoura';
  if (p.contains('jumpsuit')) return 'jumpsuit';
  if (p.contains('bisht')) return 'bisht';
  if (p.contains('kandura')) return 'kandura';
  if (p.contains('dishdasha')) return 'dishdasha';
  if (p.contains('thobe')) return 'thobe';
  if (p.contains('jubbah')) return 'jubbah';
  if (p.contains('hoodie')) return 'hoodie';
  if (p.contains('longsleeve')) return 'longsleeve';
  if (p.contains('trousers')) return 'trousers';
  if (p.contains('_tee_')) return 'tshirt';
  if (p.contains('_polo_')) return 'polo';
  return null;
}

/// Whether [path] belongs on the shopper's gender lane for [gender].
bool catalogDesignPathMatchesGenderLane(String path, String gender) {
  if (!UserGenderPreference.all.contains(gender)) return true;

  final p = path.trim().toLowerCase();
  if (p.contains('design_mod_mens_') || p.contains('_mens_')) {
    return gender == UserGenderPreference.men;
  }

  final garment = garmentTypeFromCatalogDesignPathName(path);
  if (garment == null) return true;

  final men = kBrowseCategoryGarmentTypes[UserGenderPreference.men]!;
  final women = kBrowseCategoryGarmentTypes[UserGenderPreference.women]!;
  final kids = kBrowseCategoryGarmentTypes[UserGenderPreference.kids]!;

  switch (gender) {
    case UserGenderPreference.men:
      return men.contains(garment);
    case UserGenderPreference.women:
      if (men.contains(garment) && garment != 'coat') return false;
      return women.contains(garment) ||
          kWomensExtendedGarmentTypes.contains(garment);
    case UserGenderPreference.kids:
      return kids.contains(garment) ||
          p.contains('design_casual_') ||
          garment == 'jumpsuit';
    default:
      return true;
  }
}

/// Bundled design sections filtered for [mannequinId].
List<(String sectionTitle, List<String> paths)> catalogSectionsForMannequin(
  String mannequinId,
) {
  final lane = mannequinGenderLane(mannequinId);
  return kBundledDesignCatalog
      .map((section) {
        final paths = section.$2
            .where((p) => catalogDesignPathMatchesGenderLane(p, lane))
            .toList(growable: false);
        return (section.$1, paths);
      })
      .where((section) => section.$2.isNotEmpty)
      .toList(growable: false);
}

/// All flat-lay paths visible for [mannequinId].
List<String> catalogDesignPathsForMannequin(String mannequinId) {
  return catalogSectionsForMannequin(mannequinId)
      .expand((section) => section.$2)
      .toList(growable: false);
}
