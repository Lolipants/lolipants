/// Default modular template when opening the Build tab.
const String kDefaultConfiguratorTemplateId = 'modest_abaya_v1';

/// Preferred [ConfiguratorOption.optionKey] per [ConfiguratorSlot.slotKey].
const Map<String, String> kDefaultConfiguratorOptionKeyBySlot = {
  'sleeve_length': 'three_quarter',
  'sleeve': 'three_quarter',
  'closure': 'tie_belt',
  'waistline': 'empire',
};

/// Picks the default option id for a slot (catalog order fallback).
String defaultConfiguratorOptionId(
  String slotKey,
  List<({String id, String optionKey})> options,
) {
  if (options.isEmpty) return '';
  final preferred = kDefaultConfiguratorOptionKeyBySlot[slotKey];
  if (preferred != null) {
    for (final o in options) {
      if (o.optionKey == preferred) return o.id;
    }
  }
  return options.first.id;
}
