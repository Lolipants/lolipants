import 'package:flutter/material.dart';

/// Payload passed to [EditorScreen] via `state.extra` when opening the editor
/// from a preset button (regional styles, browse grid, home grid).
///
/// All fields are optional but collectively seed the live editor state via
/// `EditorNotifier.loadPreset` so the user lands on a useful starting point
/// rather than the default thobe.
class EditorPresetArgs {
  const EditorPresetArgs({
    this.presetId,
    this.designName,
    this.garmentType,
    this.primaryColour,
    this.accentColour,
    this.fabricId,
    this.patternId,
    this.mannequinId,
  });

  final String? presetId;
  final String? designName;
  final String? garmentType;
  final Color? primaryColour;
  final Color? accentColour;
  final String? fabricId;
  final String? patternId;
  final String? mannequinId;

  Map<String, dynamic> toJson() {
    return {
      'presetId': presetId,
      'designName': designName,
      'garmentType': garmentType,
      'primaryColour': primaryColour?.toARGB32(),
      'accentColour': accentColour?.toARGB32(),
      'fabricId': fabricId,
      'patternId': patternId,
      'mannequinId': mannequinId,
    };
  }

  factory EditorPresetArgs.fromJson(Map<String, dynamic> json) {
    Color? parseColor(dynamic value) {
      if (value is int) return Color(value);
      return null;
    }

    return EditorPresetArgs(
      presetId: json['presetId']?.toString(),
      designName: json['designName']?.toString(),
      garmentType: json['garmentType']?.toString(),
      primaryColour: parseColor(json['primaryColour']),
      accentColour: parseColor(json['accentColour']),
      fabricId: json['fabricId']?.toString(),
      patternId: json['patternId']?.toString(),
      mannequinId: json['mannequinId']?.toString(),
    );
  }
}

/// Unified editor bootstrap payload for all `/editor` entry paths.
class EditorBootstrapArgs {
  const EditorBootstrapArgs({
    this.mannequinId,
    this.preset,
    this.designId,
    this.source = 'unknown',
    this.customMannequinImagePath,
  });

  final String? mannequinId;
  final EditorPresetArgs? preset;
  final String? designId;
  final String source;
  /// Local file path from image picker; used as AI / mannequin body reference.
  final String? customMannequinImagePath;

  Map<String, dynamic> toJson() {
    return {
      'mannequinId': mannequinId,
      'preset': preset?.toJson(),
      'designId': designId,
      'source': source,
      'customMannequinImagePath': customMannequinImagePath,
    };
  }

  factory EditorBootstrapArgs.fromJson(Map<String, dynamic> json) {
    final presetJson = json['preset'];
    return EditorBootstrapArgs(
      mannequinId: json['mannequinId']?.toString(),
      preset: presetJson is Map<String, dynamic>
          ? EditorPresetArgs.fromJson(presetJson)
          : null,
      designId: json['designId']?.toString(),
      source: json['source']?.toString() ?? 'unknown',
      customMannequinImagePath:
          json['customMannequinImagePath']?.toString(),
    );
  }
}
