import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';

void main() {
  group('RegionStylePreset.fromApi', () {
    test('maps image_url to preview and name_ar to subtitle', () {
      final preset = RegionStylePreset.fromApi({
        'id': 'cms-uuid-1',
        'name': 'New Gulf Thobe',
        'name_ar': 'ثوب خليجي',
        'type': 'style',
        'garment_type': 'thobe',
        'region': 'gulf',
        'image_url': 'https://cdn.example/uploads/thobe.png',
        'is_active': 1,
      });

      expect(preset.id, 'cms-uuid-1');
      expect(preset.title, 'New Gulf Thobe');
      expect(preset.subtitle, 'ثوب خليجي');
      expect(preset.region, Region.gulf);
      expect(preset.previewAssetPath, 'https://cdn.example/uploads/thobe.png');
      expect(
        preset.resolvedPreviewAssetPath,
        'https://cdn.example/uploads/thobe.png',
      );
      expect(preset.showInBrowseCatalog, isTrue);
    });

    test('excludes pattern rows from browse catalog', () {
      final preset = RegionStylePreset.fromApi({
        'id': 'pat-1',
        'name': 'Zellige',
        'type': 'pattern',
        'image_url': 'https://cdn.example/pattern.png',
      });

      expect(preset.showInBrowseCatalog, isFalse);
    });

    test('isCasualStyle uses garment_type and type', () {
      final byGarment = RegionStylePreset.fromApi({
        'id': 'x1',
        'name': 'Tee',
        'type': 'style',
        'garment_type': 'tshirt',
        'image_url': 'https://cdn.example/tee.png',
      });
      final byType = RegionStylePreset.fromApi({
        'id': 'x2',
        'name': 'Weekend',
        'type': 'casual',
        'garment_type': 'thobe',
      });

      expect(byGarment.isCasualStyle, isTrue);
      expect(byType.isCasualStyle, isTrue);
    });
  });

  group('regionPresetsForHomeShowcase', () {
    test('takes first N from pool in API order', () {
      const pool = [
        RegionStylePreset(
          id: 'a',
          title: 'A',
          subtitle: '',
          region: Region.gulf,
          garmentType: 'thobe',
          primaryColour: Color(0xFF000000),
          accentColour: Color(0xFFC9A84C),
        ),
        RegionStylePreset(
          id: 'b',
          title: 'B',
          subtitle: '',
          region: Region.gulf,
          garmentType: 'thobe',
          primaryColour: Color(0xFF000000),
          accentColour: Color(0xFFC9A84C),
        ),
      ];

      final shown = regionPresetsForHomeShowcase(pool, count: 1);
      expect(shown.length, 1);
      expect(shown.first.id, 'a');
    });
  });

  group('filterPresetCatalog', () {
    test('drops inactive and pattern presets', () {
      final out = filterPresetCatalog([
        RegionStylePreset.fromApi({
          'id': '1',
          'name': 'Style',
          'type': 'style',
          'is_active': 1,
        }),
        RegionStylePreset.fromApi({
          'id': '2',
          'name': 'Pat',
          'type': 'pattern',
          'is_active': 1,
        }),
        RegionStylePreset.fromApi({
          'id': '3',
          'name': 'Off',
          'type': 'style',
          'is_active': 0,
        }),
      ]);

      expect(out.length, 1);
      expect(out.first.id, '1');
    });
  });
}
