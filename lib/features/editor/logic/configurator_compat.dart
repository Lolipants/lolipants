import 'package:lolipants/features/editor/data/configurator_defaults.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';

const _sleeveSlotKeys = {'sleeve', 'sleeve_length'};
const _overlaySlotKeys = {'overlay_panel', 'chest_panel', 'overlay'};

/// Returns the selected [optionKey] for [slotKey], or null.
String? selectedOptionKeyForSlot({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
  required String slotKey,
}) {
  for (final slot in template.slots) {
    if (slot.slotKey != slotKey) continue;
    final optId = selections[slot.id];
    if (optId == null) return null;
    for (final o in slot.options) {
      if (o.id == optId) return o.optionKey;
    }
    return null;
  }
  return null;
}

/// Whether [option] should appear in the picker for [slot].
bool isConfiguratorOptionVisible({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
  required ConfiguratorSlot slot,
  required ConfiguratorOption option,
}) {
  final when = option.metadata['visibleWhen'];
  if (when is! Map) return true;
  final slotKey = when['slotKey']?.toString();
  final optionKey = when['optionKey']?.toString();
  if (slotKey == null || slotKey.isEmpty) return true;
  final selected = selectedOptionKeyForSlot(
    template: template,
    selections: selections,
    slotKey: slotKey,
  );
  if (optionKey == null || optionKey.isEmpty) {
    return selected != null;
  }
  return selected == optionKey;
}

/// Slot keys hidden because a selected option lists them in `suppressesSlotKeys`.
Set<String> suppressedSlotKeysFor({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
}) {
  final suppressed = <String>{};
  for (final slot in template.slots) {
    final optId = selections[slot.id];
    if (optId == null) continue;
    for (final o in slot.options) {
      if (o.id != optId) continue;
      final raw = o.metadata['suppressesSlotKeys'];
      if (raw is List) {
        for (final e in raw) {
          final key = e.toString().trim();
          if (key.isNotEmpty) suppressed.add(key);
        }
      }
      break;
    }
  }
  return suppressed;
}

/// Whether the slot tab and layer stack should include [slot].
bool isConfiguratorSlotActive({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
  required ConfiguratorSlot slot,
}) {
  return !suppressedSlotKeysFor(
    template: template,
    selections: selections,
  ).contains(slot.slotKey);
}

/// Slots shown in the design picker (excludes suppressed parts).
List<ConfiguratorSlot> activeConfiguratorSlots({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
}) {
  return template.slots
      .where(
        (s) => isConfiguratorSlotActive(
          template: template,
          selections: selections,
          slot: s,
        ),
      )
      .toList(growable: false);
}

/// False for sleeveless / `skipLayerRender` options (no overlay on mannequin).
bool shouldRenderConfiguratorLayer(ConfiguratorOption option) {
  if (option.optionKey == 'sleeveless') return false;
  final skip = option.metadata['skipLayerRender'];
  return skip != true;
}

/// Options visible for the active slot after compatibility filtering.
List<ConfiguratorOption> filteredOptionsForSlot({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
  required ConfiguratorSlot slot,
}) {
  var options = slot.options
      .where(
        (o) => isConfiguratorOptionVisible(
          template: template,
          selections: selections,
          slot: slot,
          option: o,
        ),
      )
      .toList(growable: false);

  if (_sleeveSlotKeys.contains(slot.slotKey) &&
      bodiceRequiresSleeveless(
        template: template,
        selections: selections,
      )) {
    options = options
        .where((o) => o.optionKey == 'sleeveless')
        .toList(growable: false);
  }

  return options;
}

/// True when the selected bodice option requires [sleeveless] sleeves.
bool bodiceRequiresSleeveless({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
}) {
  for (final slot in template.slots) {
    if (slot.slotKey != 'bodice') continue;
    final optId = selections[slot.id];
    if (optId == null) return false;
    for (final o in slot.options) {
      if (o.id != optId) continue;
      return o.metadata['requiresSleeveless'] == true;
    }
    return false;
  }
  return false;
}

String? _sleevelessOptionId(ConfiguratorSlot sleeveSlot) {
  for (final o in sleeveSlot.options) {
    if (o.optionKey == 'sleeveless') return o.id;
  }
  return null;
}

/// Halter / off-shoulder bodices always pair with the sleeveless option.
ConfiguratorSelections applyBodiceSleeveCoupling({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
}) {
  if (!bodiceRequiresSleeveless(
    template: template,
    selections: selections,
  )) {
    return selections;
  }

  final next = Map<String, String>.from(selections);
  for (final slot in template.slots) {
    if (!_sleeveSlotKeys.contains(slot.slotKey)) continue;
    final sleevelessId = _sleevelessOptionId(slot);
    if (sleevelessId != null) {
      next[slot.id] = sleevelessId;
    }
  }
  return next;
}

/// Clears selections that conflict with [slotId]/[optionId] being chosen.
ConfiguratorSelections resolveConfiguratorConflicts({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
  required String slotId,
  required String optionId,
}) {
  ConfiguratorOption? picked;
  for (final slot in template.slots) {
    if (slot.id != slotId) continue;
    for (final o in slot.options) {
      if (o.id == optionId) {
        picked = o;
        break;
      }
    }
    break;
  }
  if (picked == null) return selections;

  final excludesRaw = picked.metadata['excludesOptionKeys'];
  final excludes = excludesRaw is List
      ? excludesRaw.map((e) => e.toString()).toSet()
      : <String>{};

  final next = Map<String, String>.from(selections);
  next[slotId] = optionId;

  for (final slot in template.slots) {
    final selId = next[slot.id];
    if (selId == null) continue;
    for (final o in slot.options) {
      if (o.id == selId &&
          (excludes.contains(o.optionKey) || excludes.contains(o.id))) {
        next.remove(slot.id);
        break;
      }
    }
  }

  final suppressed = suppressedSlotKeysFor(
    template: template,
    selections: next,
  );
  for (final slot in template.slots) {
    if (suppressed.contains(slot.slotKey)) {
      next.remove(slot.id);
    }
  }

  final coupled = applyBodiceSleeveCoupling(
    template: template,
    selections: next,
  );

  return ensureDefaultSelectionsForActiveSlots(
    template: template,
    selections: coupled,
  );
}

/// Fills defaults when a slot becomes active again (e.g. after leaving halter).
ConfiguratorSelections ensureDefaultSelectionsForActiveSlots({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
}) {
  final next = Map<String, String>.from(selections);
  final suppressed = suppressedSlotKeysFor(
    template: template,
    selections: next,
  );
  for (final slot in template.slots) {
    if (suppressed.contains(slot.slotKey)) continue;
    if (next.containsKey(slot.id)) continue;
    if (slot.options.isEmpty) continue;
    final pick = _defaultCompatibleOptionId(
      template: template,
      selections: next,
      slot: slot,
    );
    if (pick != null) next[slot.id] = pick;
  }
  return next;
}

String? _defaultCompatibleOptionId({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
  required ConfiguratorSlot slot,
}) {
  final visible = filteredOptionsForSlot(
    template: template,
    selections: selections,
    slot: slot,
  );
  if (visible.isEmpty) return null;

  final preferred = kDefaultConfiguratorOptionKeyBySlot[slot.slotKey];
  if (preferred != null) {
    for (final o in visible) {
      if (o.optionKey == preferred && !_isOptionExcluded(selections, template, o)) {
        return o.id;
      }
    }
  }

  for (final o in visible) {
    if (!_isOptionExcluded(selections, template, o)) return o.id;
  }
  return visible.first.id;
}

bool _isOptionExcluded(
  ConfiguratorSelections selections,
  ConfiguratorTemplate template,
  ConfiguratorOption option,
) {
  for (final slot in template.slots) {
    final selId = selections[slot.id];
    if (selId == null) continue;
    for (final o in slot.options) {
      if (o.id != selId) continue;
      final excludesRaw = o.metadata['excludesOptionKeys'];
      if (excludesRaw is! List) break;
      final excludes = excludesRaw.map((e) => e.toString()).toSet();
      if (excludes.contains(option.optionKey) || excludes.contains(option.id)) {
        return true;
      }
      break;
    }
  }
  return false;
}

/// True when every [template.requiredSlotKeys] has a selection.
bool configuratorRequiredSlotsFilled({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
}) {
  final suppressed = suppressedSlotKeysFor(
    template: template,
    selections: selections,
  );

  if (template.requiredSlotKeys.isEmpty) {
    return template.slots.every((s) {
      if (suppressed.contains(s.slotKey)) return true;
      if (s.options.isEmpty) return true;
      return selections.containsKey(s.id);
    });
  }
  for (final key in template.requiredSlotKeys) {
    if (suppressed.contains(key)) continue;
    ConfiguratorSlot? slot;
    for (final s in template.slots) {
      if (s.slotKey == key) {
        slot = s;
        break;
      }
    }
    if (slot == null) continue;
    if (slot.options.isEmpty) continue;
    if (!selections.containsKey(slot.id)) return false;
  }
  return true;
}

/// Human-readable missing-slot message for checkout guard.
String? configuratorRequiredSlotsMessage({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
}) {
  if (configuratorRequiredSlotsFilled(
    template: template,
    selections: selections,
  )) {
    return null;
  }
  final missing = <String>[];
  final suppressed = suppressedSlotKeysFor(
    template: template,
    selections: selections,
  );
  for (final key in template.requiredSlotKeys) {
    if (suppressed.contains(key)) continue;
    for (final slot in template.slots) {
      if (slot.slotKey != key) continue;
      if (slot.options.isEmpty) continue;
      if (!selections.containsKey(slot.id)) {
        missing.add(slot.titleEn);
      }
    }
  }
  if (missing.isEmpty) {
    return 'Please complete all garment options before ordering.';
  }
  return 'Please choose: ${missing.join(', ')}';
}

ConfiguratorOption? _selectedOptionForSlot({
  required ConfiguratorSlot slot,
  required ConfiguratorSelections selections,
}) {
  final optId = selections[slot.id];
  if (optId == null) return null;
  for (final o in slot.options) {
    if (o.id == optId) return o;
  }
  return null;
}

bool _isOverlaySlot(ConfiguratorSlot slot) {
  if (_overlaySlotKeys.contains(slot.slotKey)) return true;
  return slot.slotKey.contains('overlay') || slot.slotKey.contains('chest');
}

/// Explicit layer semantics for AI look generation (sleeves vs chest overlays).
String configuratorAiLayerNotesText({
  required ConfiguratorTemplate template,
  required ConfiguratorSelections selections,
}) {
  final lines = <String>[
    'AI layer interpretation (critical — do not misread preview overlays):',
    '- Preview PNG layers are flat composited graphics, not separate physical parts.',
    '- CHEST / OVERLAY panels are front-torso decorations ONLY — never extend them down the arms as sleeves.',
  ];

  final suppressed = suppressedSlotKeysFor(
    template: template,
    selections: selections,
  );

  var anySleeveSlot = false;
  for (final slot in template.slots) {
    if (!_sleeveSlotKeys.contains(slot.slotKey)) continue;
    anySleeveSlot = true;

    if (suppressed.contains(slot.slotKey)) {
      lines.add(
        '- ${slot.titleEn} (${slot.slotKey}): NOT USED — slot suppressed; arms must have NO sleeve fabric.',
      );
      continue;
    }

    if (!isConfiguratorSlotActive(
      template: template,
      selections: selections,
      slot: slot,
    )) {
      continue;
    }

    final chosen = _selectedOptionForSlot(slot: slot, selections: selections);
    if (chosen == null) {
      lines.add(
        '- ${slot.titleEn}: no selection — treat as no dedicated sleeve layer.',
      );
      continue;
    }

    if (!shouldRenderConfiguratorLayer(chosen)) {
      lines.add(
        '- ${slot.titleEn}: "${chosen.labelEn}" — NO SLEEVES on this design. '
        'Arms stay bare / show base bodice only. Do NOT add or infer sleeve fabric.',
      );
    } else {
      lines.add(
        '- ${slot.titleEn}: "${chosen.labelEn}" — active sleeve layer; apply fabric ONLY to arms, not chest overlay.',
      );
    }
  }

  if (!anySleeveSlot) {
    lines.add(
      '- This template has no sleeve slot — do not add sleeves unless explicitly shown in the preview.',
    );
  }

  for (final slot in template.slots) {
    if (!_isOverlaySlot(slot)) continue;
    if (suppressed.contains(slot.slotKey)) continue;
    if (!isConfiguratorSlotActive(
      template: template,
      selections: selections,
      slot: slot,
    )) {
      continue;
    }

    final chosen = _selectedOptionForSlot(slot: slot, selections: selections);
    if (chosen == null || !shouldRenderConfiguratorLayer(chosen)) continue;
    lines.add(
      '- ${slot.titleEn}: "${chosen.labelEn}" — chest/front overlay panel only; NOT sleeves, NOT arm extensions.',
    );
  }

  return lines.join('\n');
}
