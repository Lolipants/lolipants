import 'package:flutter/material.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/logic/catalog_design_gender_filter.dart';
import 'package:lolipants/features/editor/models/design_catalog_item.dart';

/// Resolves the lane used for home featured designs (kids → women).
String effectiveFeaturedGenderLane(String? gender) {
  if (gender == UserGenderPreference.kids) {
    return UserGenderPreference.women;
  }
  if (gender != null && UserGenderPreference.all.contains(gender)) {
    return gender;
  }
  return UserGenderPreference.women;
}

Region _regionFromDesignPath(String path) {
  final p = path.toLowerCase();
  if (p.contains('_gulf_')) return Region.gulf;
  if (p.contains('_lev_')) return Region.levant;
  if (p.contains('_mag_')) return Region.maghreb;
  return Region.modern;
}

/// Maps a bundled flat-lay asset to a home/browse [RegionStylePreset] tile.
RegionStylePreset regionStylePresetFromFlatLayPath(String assetPath) {
  final garment =
      garmentTypeFromCatalogDesignPathName(assetPath) ?? 'dress';
  return RegionStylePreset(
    id: 'flatlay_${assetPath.hashCode.abs()}',
    title: catalogDesignLabel(assetPath),
    subtitle: garment,
    region: _regionFromDesignPath(assetPath),
    garmentType: garment,
    primaryColour: const Color(0xFF1F2233),
    accentColour: const Color(0xFFC9A84C),
    previewAssetPath: assetPath,
  );
}

/// Maps a CMS catalog row to a home featured tile.
RegionStylePreset regionStylePresetFromCatalogItem(DesignCatalogItem item) {
  final path = item.imageUrl.trim();
  final garment = item.garmentType?.trim().isNotEmpty == true
      ? item.garmentType!.trim()
      : garmentTypeFromCatalogDesignPathName(path) ?? 'dress';
  return RegionStylePreset(
    id: 'catalog_${item.id}',
    title: item.labelEn.trim().isNotEmpty
        ? item.labelEn.trim()
        : catalogDesignLabel(path),
    subtitle: garment,
    region: _regionFromDesignPath(path),
    garmentType: garment,
    primaryColour: const Color(0xFF1F2233),
    accentColour: const Color(0xFFC9A84C),
    previewAssetPath: path,
  );
}

/// Featured flat-lay designs for the shopper lane ([gender] from `users.gender`).
List<RegionStylePreset> buildHomeFeaturedDesigns({
  required String? gender,
  required List<DesignCatalogItem> cmsItems,
  int count = 8,
}) {
  final lane = effectiveFeaturedGenderLane(gender);
  final seen = <String>{};
  final out = <RegionStylePreset>[];

  void add(RegionStylePreset preset) {
    final key = preset.resolvedPreviewAssetPath ?? preset.id;
    if (key.isEmpty || seen.contains(key)) return;
    seen.add(key);
    out.add(preset);
  }

  final bundledPaths = switch (lane) {
    UserGenderPreference.men => kMenCompleteLookPaths,
    UserGenderPreference.women => kWomenCompleteLookPaths,
    _ => [...kWomenCompleteLookPaths, ...kMenCompleteLookPaths],
  };

  for (final path in bundledPaths) {
    if (!catalogDesignPathMatchesGenderLane(path, lane)) continue;
    add(regionStylePresetFromFlatLayPath(path));
    if (out.length >= count) {
      return out.take(count).toList(growable: false);
    }
  }

  final sortedCms = [...cmsItems]
    ..sort((a, b) {
      final section = a.sectionTitle.compareTo(b.sectionTitle);
      if (section != 0) return section;
      return a.sortOrder.compareTo(b.sortOrder);
    });

  for (final item in sortedCms) {
    if (!designCatalogItemMatchesGenderLane(item, lane)) continue;
    if (item.imageUrl.trim().isEmpty) continue;
    add(regionStylePresetFromCatalogItem(item));
    if (out.length >= count) {
      return out.take(count).toList(growable: false);
    }
  }

  return out;
}
