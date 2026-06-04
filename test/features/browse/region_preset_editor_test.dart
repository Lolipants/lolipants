import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/logic/region_preset_editor.dart';

void main() {
  test('maps region preset to editor preset with catalogue path', () {
    const preset = RegionStylePreset(
      id: 'lev_kaftan',
      title: 'Levant kaftan',
      subtitle: 'Dress',
      region: Region.levant,
      garmentType: 'dress',
      primaryColour: Color(0xFF111111),
      accentColour: Color(0xFFC9A84C),
      previewAssetPath:
          'assets/images/designs/design_womens_look_lev_kaftan_aubergine.png',
    );

    final args = editorPresetArgsFromRegionPreset(preset);
    expect(args.catalogDesignPath, preset.previewAssetPath);
    expect(args.presetId, 'lev_kaftan');
    expect(
      editorPresetWithMannequin(args, 'standard_female').mannequinId,
      'standard_female',
    );
  });
}
