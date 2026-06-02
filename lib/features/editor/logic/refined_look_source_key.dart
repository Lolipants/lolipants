import 'package:flutter/material.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

/// Stable id for the design inputs that produced [EditorState.refinedLookUrl].
String refinedLookSourceKeyForEditorState(EditorState state) {
  if (state.buildStyleMode == EditorBuildStyleMode.catalog) {
    return 'catalog:${state.selectedCatalogDesignPath.trim()}';
  }
  final templateId = state.configuratorTemplateId.trim();
  if (templateId.isEmpty) return 'generic';
  final entries = state.configuratorSelections.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final sel = entries.map((e) => '${e.key}=${e.value}').join('|');
  return 'cfg:$templateId:$sel:${state.selectedFabricId.trim()}:'
      '${_colorToHex(state.primaryColour)}:${_colorToHex(state.accentColour)}';
}

String _colorToHex(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}
