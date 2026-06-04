import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';

/// Seeds [EditorNotifier.loadPreset] from a home/browse design tile.
EditorPresetArgs editorPresetArgsFromRegionPreset(RegionStylePreset preset) {
  return EditorPresetArgs(
    presetId: preset.id,
    designName: preset.title,
    garmentType: preset.garmentType,
    primaryColour: preset.primaryColour,
    accentColour: preset.accentColour,
    fabricId: preset.fabricId,
    catalogDesignPath: preset.resolvedPreviewAssetPath,
  );
}

/// Applies the mannequin picked on the previous screen.
EditorPresetArgs editorPresetWithMannequin(
  EditorPresetArgs preset,
  String mannequinId,
) {
  return EditorPresetArgs(
    presetId: preset.presetId,
    designName: preset.designName,
    garmentType: preset.garmentType,
    primaryColour: preset.primaryColour,
    accentColour: preset.accentColour,
    fabricId: preset.fabricId,
    patternId: preset.patternId,
    mannequinId: mannequinId,
    catalogDesignPath: preset.catalogDesignPath,
  );
}
