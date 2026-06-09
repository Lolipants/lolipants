/// Maps AI / free-text fabric tokens to a known catalogue fabric id.
String resolveFabricIdToken(String? raw, List<String> availableIds) {
  if (availableIds.isEmpty) return '';

  final current = raw?.trim() ?? '';
  if (current.isNotEmpty && availableIds.contains(current)) {
    return current;
  }

  final normalized = _normalizeToken(raw);
  if (normalized == null) {
    return availableIds.first;
  }

  const aliases = <String, String>{
    'cotton': 'cotton',
    'cotton blend': 'cotton',
    'linen': 'linen',
    'flax': 'linen',
    'silk': 'silk',
    'satin': 'silk',
    'crepe': 'crepe',
    'crape': 'crepe',
    'chiffon': 'chiffon',
    'sheer': 'chiffon',
  };

  if (aliases.containsKey(normalized)) {
    final alias = aliases[normalized]!;
    if (availableIds.contains(alias)) return alias;
  }

  final matched = _bestTokenMatch(normalized, availableIds);
  if (matched != null) return matched;

  return availableIds.first;
}

String? _normalizeToken(String? value) {
  if (value == null) return null;
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) return null;
  return normalized;
}

String? _bestTokenMatch(String input, List<String> options) {
  for (final option in options) {
    if (input == option) return option;
  }
  for (final option in options) {
    if (input.contains(option) || option.contains(input)) {
      return option;
    }
  }
  final words = input.split(' ');
  for (final word in words) {
    for (final option in options) {
      if (word == option || option.contains(word) || word.contains(option)) {
        return option;
      }
    }
  }
  return null;
}
