import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/models/design_text_layer.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/features/editor/models/print_placement.dart';

/// Values restored when reopening a saved design in the editor.
class EditorDesignRestoreSnapshot {
  const EditorDesignRestoreSnapshot({
    required this.garmentType,
    required this.catalogDesignPath,
    required this.printPlacement,
    required this.printOffsetX,
    required this.printOffsetY,
    required this.printScale,
    required this.textLayers,
    required this.isCasual,
  });

  final String garmentType;
  final String catalogDesignPath;
  final PrintPlacement printPlacement;
  final double printOffsetX;
  final double printOffsetY;
  final double printScale;
  final List<DesignTextLayer> textLayers;
  final bool isCasual;
}

/// Builds editor state fields from API design + merged render metadata.
EditorDesignRestoreSnapshot editorDesignRestoreSnapshot(GarmentDesign design) {
  final meta = design.renderMetadata ?? const <String, dynamic>{};
  final printTransform = _mapOrEmpty(meta['printTransform']);

  var catalogPath = catalogDesignAssetFromRenderMetadata(meta) ??
      _nonEmpty(meta['catalogDesignPath']) ??
      _nonEmpty(meta['selectedCatalogDesignPath']);

  var garmentType = design.garmentType.trim();
  if (garmentType.isEmpty) {
    garmentType = _nonEmpty(meta['garmentType']) ?? kDefaultCasualGarmentType;
  }

  if (catalogPath != null && isCasualCatalogDesignPath(catalogPath)) {
    garmentType = garmentTypeFromCatalogDesignPath(catalogPath);
  } else if (kCasualGarmentTypes.contains(garmentType) && catalogPath == null) {
    catalogPath = kCasualFlatlayPaths.first;
  }

  final isCasual = kCasualGarmentTypes.contains(garmentType) ||
      (catalogPath != null && isCasualCatalogDesignPath(catalogPath));

  if (catalogPath == null || catalogPath.isEmpty) {
    catalogPath = isCasual
        ? kCasualFlatlayPaths.first
        : kDefaultCatalogDesignPath;
  }

  final placementRaw = _nonEmpty(printTransform['placement']) ??
      _nonEmpty(meta['printPlacement']);

  return EditorDesignRestoreSnapshot(
    garmentType: garmentType,
    catalogDesignPath: catalogPath,
    printPlacement: parsePrintPlacement(placementRaw),
    printOffsetX: _num(printTransform['x'] ?? meta['printOffsetX'], 0),
    printOffsetY: _num(printTransform['y'] ?? meta['printOffsetY'], 0),
    printScale: _num(printTransform['scale'] ?? meta['printScale'], 40)
        .clamp(20.0, 120.0),
    textLayers: _parseTextLayers(meta['textLayers'] ?? meta['text_layers']),
    isCasual: isCasual,
  );
}

List<DesignTextLayer> _parseTextLayers(dynamic raw) {
  final items = <dynamic>[];
  if (raw is List) {
    items.addAll(raw);
  } else if (raw is String && raw.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) items.addAll(decoded);
    } on FormatException {
      return const [];
    }
  }

  final layers = <DesignTextLayer>[];
  var index = 0;
  for (final item in items) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final text = map['text']?.toString().trim() ?? '';
    if (text.isEmpty) continue;
    layers.add(
      DesignTextLayer(
        id: map['id']?.toString() ?? 'layer_$index',
        text: text,
        fontFamily: map['fontFamily']?.toString() ?? 'Poppins',
        fontSize: _num(map['fontSize'], 20).clamp(8.0, 96.0),
        colour: _parseHexColor(
          map['colour']?.toString() ?? map['color']?.toString() ?? '#1B1621',
        ),
        placement: Offset(
          _num(map['x'] ?? map['placementX'], 0.5).clamp(0.05, 0.95),
          _num(map['y'] ?? map['placementY'], 0.5).clamp(0.1, 0.98),
        ),
        rotation: _num(map['rotation'], 0),
      ),
    );
    index++;
  }
  return layers;
}

Map<String, dynamic> _mapOrEmpty(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

String? _nonEmpty(dynamic value) {
  final s = value?.toString().trim();
  if (s == null || s.isEmpty) return null;
  return s;
}

double _num(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

Color _parseHexColor(String hex) {
  var normalized = hex.trim();
  if (normalized.startsWith('#')) {
    normalized = normalized.substring(1);
  }
  if (normalized.length == 6) {
    normalized = 'FF$normalized';
  }
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return const Color(0xFF1B1621);
  return Color(value);
}

/// Merges top-level API `text_layers` into render metadata when missing.
Map<String, dynamic>? mergeDesignRenderMetadata(Map<String, dynamic> json) {
  Map<String, dynamic>? meta;
  final rawMeta = json['render_metadata'] ?? json['renderMetadata'];
  if (rawMeta is Map<String, dynamic>) {
    meta = Map<String, dynamic>.from(rawMeta);
  } else if (rawMeta is String && rawMeta.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(rawMeta);
      if (decoded is Map<String, dynamic>) {
        meta = Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      meta = null;
    }
  }

  meta ??= <String, dynamic>{};
  if (meta['textLayers'] == null && meta['text_layers'] == null) {
    final fromColumn = json['text_layers'] ?? json['textLayers'];
    if (fromColumn != null) {
      meta['textLayers'] = fromColumn;
    }
  }
  return meta;
}
