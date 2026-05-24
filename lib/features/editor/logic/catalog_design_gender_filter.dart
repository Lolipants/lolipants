import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/data/preset_gender_filter.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/logic/mannequin_gender.dart';
import 'package:lolipants/features/editor/models/catalog_design_pick.dart';
import 'package:lolipants/features/editor/models/design_catalog_item.dart';

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

/// Whether [garmentType] belongs on the shopper's gender lane.
bool garmentTypeMatchesGenderLane(String garmentType, String gender) {
  if (!UserGenderPreference.all.contains(gender)) return true;

  final men = kBrowseCategoryGarmentTypes[UserGenderPreference.men]!;
  final women = kBrowseCategoryGarmentTypes[UserGenderPreference.women]!;
  final kids = kBrowseCategoryGarmentTypes[UserGenderPreference.kids]!;

  switch (gender) {
    case UserGenderPreference.men:
      return men.contains(garmentType);
    case UserGenderPreference.women:
      if (men.contains(garmentType) && garmentType != 'coat') return false;
      return women.contains(garmentType) ||
          kWomensExtendedGarmentTypes.contains(garmentType);
    case UserGenderPreference.kids:
      return kids.contains(garmentType) || garmentType == 'jumpsuit';
    default:
      return true;
  }
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
  return garmentTypeMatchesGenderLane(garment, gender);
}

bool _cmsDesignMatchesGenderLane(DesignCatalogItem item, String gender) {
  final lane = item.genderLane?.trim();
  if (lane != null && lane.isNotEmpty) {
    return lane == gender;
  }
  final garment = item.garmentType?.trim();
  if (garment != null && garment.isNotEmpty) {
    return garmentTypeMatchesGenderLane(garment, gender);
  }
  return true;
}

CatalogDesignPick _bundledPick(String path) => CatalogDesignPick(
      ref: path,
      label: catalogDesignLabel(path),
      imageSource: path,
    );

/// Bundled design sections filtered for [mannequinId].
List<CatalogDesignSection> bundledCatalogSectionsForMannequin(
  String mannequinId,
) {
  final lane = mannequinGenderLane(mannequinId);
  return kBundledDesignCatalog
      .map((section) {
        final picks = section.$2
            .where((p) => catalogDesignPathMatchesGenderLane(p, lane))
            .map(_bundledPick)
            .toList(growable: false);
        return (section.$1, picks);
      })
      .where((section) => section.$2.isNotEmpty)
      .toList(growable: false);
}

List<CatalogDesignSection> _cmsSectionsForMannequin(
  String mannequinId,
  List<DesignCatalogItem> items,
) {
  if (items.isEmpty) return const [];
  final lane = mannequinGenderLane(mannequinId);
  final bySection = <String, List<CatalogDesignPick>>{};
  for (final item in items) {
    if (!_cmsDesignMatchesGenderLane(item, lane)) continue;
    if (item.imageUrl.trim().isEmpty) continue;
    final title = item.sectionTitle.trim().isEmpty ? 'Catalog' : item.sectionTitle;
    bySection.putIfAbsent(title, () => []).add(item.toPick());
  }
  final sections = bySection.entries
      .map((e) => (e.key, e.value))
      .toList(growable: false);
  sections.sort((a, b) => a.$1.compareTo(b.$1));
  return sections;
}

/// Bundled flats plus CMS rows, merged by section title.
List<CatalogDesignSection> mergedCatalogSectionsForMannequin({
  required String mannequinId,
  List<DesignCatalogItem>? cmsItems,
}) {
  final bundled = bundledCatalogSectionsForMannequin(mannequinId);
  final cms = _cmsSectionsForMannequin(mannequinId, cmsItems ?? const []);
  if (cms.isEmpty) return bundled;
  if (bundled.isEmpty) return cms;

  final merged = <String, List<CatalogDesignPick>>{};
  for (final (title, picks) in bundled) {
    merged[title] = [...picks];
  }
  for (final (title, picks) in cms) {
    merged.putIfAbsent(title, () => []).addAll(picks);
  }
  return merged.entries.map((e) => (e.key, e.value)).toList(growable: false);
}

/// Bundled design sections filtered for [mannequinId] (legacy path list).
List<(String sectionTitle, List<String> paths)> catalogSectionsForMannequin(
  String mannequinId,
) {
  return bundledCatalogSectionsForMannequin(mannequinId)
      .map((section) => (section.$1, section.$2.map((p) => p.ref).toList()))
      .toList(growable: false);
}

/// All flat-lay refs visible for [mannequinId] (bundled paths only).
List<String> catalogDesignPathsForMannequin(String mannequinId) {
  return bundledCatalogSectionsForMannequin(mannequinId)
      .expand((section) => section.$2.map((p) => p.ref))
      .toList(growable: false);
}
