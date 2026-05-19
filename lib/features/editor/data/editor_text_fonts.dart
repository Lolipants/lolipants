import 'package:flutter/material.dart';
import 'package:lolipants/features/editor/data/bundled_editor_font_assets.dart';

/// One selectable font for T-shirt / casual text layers.
class EditorTextFont {
  const EditorTextFont({
    required this.id,
    required this.label,
    required this.previewSample,
    required this.build,
  });

  /// Stored on [EditorTextLayer.fontFamily] and in saved designs.
  final String id;

  /// Short label in the font picker chips.
  final String label;

  /// Characters shown in the chip preview.
  final String previewSample;

  /// Builds the layer style (bundled asset or Google Fonts).
  final TextStyle Function({
    required double fontSize,
    required Color color,
  }) build;
}

EditorTextFont _bundledFont({
  required String family,
  required String label,
  String previewSample = 'Aa',
}) {
  return EditorTextFont(
    id: family,
    label: label,
    previewSample: previewSample,
    build: ({required fontSize, required color}) => TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      color: color,
    ),
  );
}

/// Core UI fonts plus every custom face in [assets/fonts/].
final List<EditorTextFont> kCasualEditorTextFonts = <EditorTextFont>[
  _bundledFont(family: 'Poppins', label: 'Poppins'),
  _bundledFont(
    family: 'NotoNaskhArabic',
    label: 'Naskh',
    previewSample: 'ع',
  ),
  for (final asset in kBundledEditorFontAssets)
    _bundledFont(
      family: asset.family,
      label: asset.label,
      previewSample: asset.isArabic ? 'ع' : asset.previewSample,
    ),
];

/// Legacy [fontFamily] ids from older builds → current [EditorTextFont.id].
const Map<String, String> _legacyFontIds = <String, String>{
  'PlayfairDisplay': 'Playfair Display',
  'RobotoMono': 'Roboto Mono',
  'DancingScript': 'Dancing Script',
};

/// Normalizes stored font ids (including legacy compact names).
String normalizeEditorFontId(String? fontFamily) {
  if (fontFamily == null || fontFamily.isEmpty) {
    return kCasualEditorTextFonts.first.id;
  }
  return _legacyFontIds[fontFamily] ?? fontFamily;
}

/// Resolves a stored font id (including legacy names) to a picker entry.
EditorTextFont? editorTextFontById(String? fontFamily) {
  if (fontFamily == null || fontFamily.isEmpty) {
    return kCasualEditorTextFonts.first;
  }
  final normalized = normalizeEditorFontId(fontFamily);
  for (final font in kCasualEditorTextFonts) {
    if (font.id == normalized) {
      return font;
    }
  }
  return null;
}

/// Text style for rendering a casual text layer on the garment preview.
TextStyle editorLayerTextStyle({
  required String fontFamily,
  required double fontSize,
  required Color color,
}) {
  final font = editorTextFontById(fontFamily);
  if (font != null) {
    return font.build(fontSize: fontSize, color: color);
  }
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    color: color,
  );
}
