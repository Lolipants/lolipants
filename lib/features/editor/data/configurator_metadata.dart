import 'package:lolipants/features/editor/models/configurator_catalog.dart';

const String kConfiguratorMetadataKey = 'configurator';

/// Reads configurator block from design `render_metadata`.
({
  String? templateId,
  ConfiguratorSelections selections,
  String? summary,
  String? aiLayerNotes,
})
parseConfiguratorFromRenderMetadata(Map<String, dynamic>? meta) {
  if (meta == null) {
    return (templateId: null, selections: {}, summary: null, aiLayerNotes: null);
  }
  final block = meta[kConfiguratorMetadataKey];
  if (block is! Map<String, dynamic>) {
    return (templateId: null, selections: {}, summary: null, aiLayerNotes: null);
  }
  final templateId = block['templateId']?.toString();
  final summary = block['summary']?.toString();
  final aiLayerNotes = block['aiLayerNotes']?.toString();
  final selRaw = block['selections'];
  final selections = <String, String>{};
  if (selRaw is Map) {
    selRaw.forEach((key, value) {
      final k = key.toString();
      final v = value?.toString() ?? '';
      if (k.isNotEmpty && v.isNotEmpty) selections[k] = v;
    });
  }
  return (
    templateId: templateId,
    selections: selections,
    summary: summary,
    aiLayerNotes: aiLayerNotes,
  );
}

Map<String, dynamic> buildConfiguratorMetadataBlock({
  required String templateId,
  required ConfiguratorSelections selections,
  required String summary,
  String? aiLayerNotes,
}) {
  return {
    'templateId': templateId,
    'selections': Map<String, String>.from(selections),
    'summary': summary,
    if (aiLayerNotes != null && aiLayerNotes.trim().isNotEmpty)
      'aiLayerNotes': aiLayerNotes.trim(),
  };
}
