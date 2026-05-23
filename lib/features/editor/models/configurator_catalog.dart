import 'package:lolipants/features/editor/logic/configurator_compat.dart';
import 'package:lolipants/features/editor/utils/layer_tint.dart';

/// Remote or bundled modular garment configurator catalogue.

class ConfiguratorCatalog {
  const ConfiguratorCatalog({required this.templates});

  final List<ConfiguratorTemplate> templates;

  factory ConfiguratorCatalog.fromApi(List<dynamic> json) {
    return ConfiguratorCatalog(
      templates: json
          .whereType<Map<String, dynamic>>()
          .map(ConfiguratorTemplate.fromApi)
          .where((t) => t.id.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class ConfiguratorTemplate {
  const ConfiguratorTemplate({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.garmentType,
    required this.regionTag,
    required this.sortOrder,
    required this.requiredSlotKeys,
    required this.slots,
    this.layerTintEnabled = true,
  });

  factory ConfiguratorTemplate.fromApi(Map<String, dynamic> json) {
    final slotsRaw = json['slots'];
    final slots = slotsRaw is List
        ? slotsRaw
            .whereType<Map<String, dynamic>>()
            .map(ConfiguratorSlot.fromApi)
            .toList(growable: false)
        : const <ConfiguratorSlot>[];
    final req = json['requiredSlotKeys'];
    final tintRaw = json['layerTintEnabled'];
    return ConfiguratorTemplate(
      id: json['id']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
      garmentType: json['garmentType']?.toString() ?? 'abaya',
      regionTag: json['regionTag']?.toString() ?? 'modest',
      sortOrder: _asInt(json['sortOrder']),
      requiredSlotKeys: req is List
          ? req.map((e) => e.toString()).toList(growable: false)
          : const [],
      slots: slots,
      layerTintEnabled: tintRaw is bool ? tintRaw : true,
    );
  }

  final String id;
  final String nameEn;
  final String nameAr;
  final String garmentType;
  final String regionTag;
  final int sortOrder;
  final List<String> requiredSlotKeys;
  final List<ConfiguratorSlot> slots;
  final bool layerTintEnabled;
}

class ConfiguratorSlot {
  const ConfiguratorSlot({
    required this.id,
    required this.slotKey,
    required this.titleEn,
    required this.titleAr,
    required this.sortOrder,
    required this.options,
  });

  factory ConfiguratorSlot.fromApi(Map<String, dynamic> json) {
    final optsRaw = json['options'];
    return ConfiguratorSlot(
      id: json['id']?.toString() ?? '',
      slotKey: json['slotKey']?.toString() ?? '',
      titleEn: json['titleEn']?.toString() ?? '',
      titleAr: json['titleAr']?.toString() ?? '',
      sortOrder: _asInt(json['sortOrder']),
      options: optsRaw is List
          ? optsRaw
              .whereType<Map<String, dynamic>>()
              .map(ConfiguratorOption.fromApi)
              .toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String slotKey;
  final String titleEn;
  final String titleAr;
  final int sortOrder;
  final List<ConfiguratorOption> options;
}

class ConfiguratorOption {
  const ConfiguratorOption({
    required this.id,
    required this.optionKey,
    required this.labelEn,
    required this.labelAr,
    required this.assetUrl,
    required this.metadata,
    required this.sortOrder,
  });

  factory ConfiguratorOption.fromApi(Map<String, dynamic> json) {
    final meta = json['metadata'];
    return ConfiguratorOption(
      id: json['id']?.toString() ?? '',
      optionKey: json['optionKey']?.toString() ?? '',
      labelEn: json['labelEn']?.toString() ?? '',
      labelAr: json['labelAr']?.toString() ?? '',
      assetUrl: json['assetUrl']?.toString(),
      metadata: meta is Map<String, dynamic> ? meta : const {},
      sortOrder: _asInt(json['sortOrder']),
    );
  }

  final String id;
  final String optionKey;
  final String labelEn;
  final String labelAr;
  final String? assetUrl;
  final Map<String, dynamic> metadata;
  final int sortOrder;

  /// Bundled `assets/...` path from admin metadata, or null.
  String? get bundledAssetPath {
    final raw = metadata['assetPath'];
    if (raw is! String) return null;
    final p = raw.trim();
    if (p.startsWith('assets/')) return p;
    return null;
  }

  int get layerZ {
    final z = metadata['layerZ'];
    if (z is int) return z;
    if (z is num) return z.toInt();
    return 0;
  }

  ConfiguratorTintRole get tintRole => parseTintRole(metadata);

  /// Whether this option accepts tint when [template] has tinting enabled.
  bool isTintableFor(ConfiguratorTemplate template) =>
      template.layerTintEnabled && tintRole != ConfiguratorTintRole.none;
}

/// User selection: slot id → option id.
typedef ConfiguratorSelections = Map<String, String>;

/// Selected options across [template.slots], sorted by [ConfiguratorOption.layerZ].
List<ConfiguratorOption> collectConfiguratorLayers({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
}) {
  final layers = <ConfiguratorOption>[];
  final suppressed = suppressedSlotKeysFor(
    template: template,
    selections: selections,
  );
  for (final slot in template.slots) {
    if (suppressed.contains(slot.slotKey)) continue;
    final optId = selections[slot.id];
    if (optId == null) continue;
    for (final o in slot.options) {
      if (o.id == optId) {
        if (shouldRenderConfiguratorLayer(o)) {
          layers.add(o);
        }
        break;
      }
    }
  }
  layers.sort((a, b) => a.layerZ.compareTo(b.layerZ));
  return layers;
}

/// Single-line readable design description for the hero summary bar.
String configuratorSummaryLine({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
}) {
  final parts = <String>[template.nameEn];
  for (final slot in template.slots) {
    final optId = selections[slot.id];
    if (optId == null) continue;
    for (final o in slot.options) {
      if (o.id == optId) {
        parts.add(o.labelEn);
        break;
      }
    }
  }
  return parts.join(' · ');
}

/// Arabic companion line (slot labels where available).
String configuratorSummaryLineAr({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
}) {
  final parts = <String>[template.nameAr.isNotEmpty ? template.nameAr : template.nameEn];
  for (final slot in template.slots) {
    final optId = selections[slot.id];
    if (optId == null) continue;
    for (final o in slot.options) {
      if (o.id == optId) {
        final label = o.labelAr.trim().isNotEmpty ? o.labelAr : o.labelEn;
        parts.add(label);
        break;
      }
    }
  }
  return parts.join(' · ');
}

/// Builds a quote-style summary line per slot.
String configuratorSummaryText({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
  String? designName,
}) {
  final lines = <String>[];
  if (designName != null && designName.trim().isNotEmpty) {
    lines.add('Design name — ${designName.trim()}');
  }
  lines.add('Template — ${template.nameEn}');
  for (final slot in template.slots) {
    final optId = selections[slot.id];
    ConfiguratorOption? chosen;
    for (final o in slot.options) {
      if (o.id == optId) {
        chosen = o;
        break;
      }
    }
    final label = chosen?.labelEn ?? 'Not selected';
    lines.add('${slot.titleEn} — $label');
  }
  return lines.join('\n');
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return 0;
}
