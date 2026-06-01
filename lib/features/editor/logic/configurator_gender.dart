import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/data/preset_gender_filter.dart';
import 'package:lolipants/features/editor/data/configurator_defaults.dart';
import 'package:lolipants/features/editor/logic/mannequin_gender.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';

/// Whether [template] targets the men's design lane.
bool isMensConfiguratorTemplate(ConfiguratorTemplate template) {
  final id = template.id.toLowerCase();
  if (id.contains('mens_') || id.contains('_mens') || id.contains('thobe')) {
    return true;
  }
  final tag = template.regionTag.toLowerCase();
  if (tag == 'mens' || tag == 'men' || tag == 'male') return true;
  final men = kBrowseCategoryGarmentTypes[UserGenderPreference.men]!;
  return men.contains(template.garmentType);
}

/// Whether [template] targets the women's design lane.
bool isWomensConfiguratorTemplate(ConfiguratorTemplate template) {
  if (isMensConfiguratorTemplate(template)) return false;
  final id = template.id.toLowerCase();
  if (id.contains('abaya') || id.contains('modest')) return true;
  final tag = template.regionTag.toLowerCase();
  if (tag == 'modest' || tag == 'women' || tag == 'female') return true;
  final women = kBrowseCategoryGarmentTypes[UserGenderPreference.women]!;
  if (women.contains(template.garmentType)) return true;
  return kWomensExtendedGarmentTypes.contains(template.garmentType);
}

/// Whether [template] belongs on the shopper's [gender] lane.
bool configuratorTemplateMatchesGender(
  ConfiguratorTemplate template,
  String gender,
) {
  switch (gender) {
    case UserGenderPreference.men:
      return isMensConfiguratorTemplate(template);
    case UserGenderPreference.women:
      return isWomensConfiguratorTemplate(template);
    case UserGenderPreference.kids:
      final kids = kBrowseCategoryGarmentTypes[UserGenderPreference.kids]!;
      return kids.contains(template.garmentType);
    default:
      return true;
  }
}

/// Configurator templates available for [mannequinId] (strict gender lane).
List<ConfiguratorTemplate> configuratorTemplatesForMannequin(
  List<ConfiguratorTemplate> templates,
  String mannequinId,
) {
  final lane = mannequinGenderLane(mannequinId);
  final matched = templates
      .where((t) => configuratorTemplateMatchesGender(t, lane))
      .toList(growable: false);
  matched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return matched;
}

/// Puts gender-matching templates first, then preserves [sortOrder].
List<ConfiguratorTemplate> sortConfiguratorTemplatesForGender(
  List<ConfiguratorTemplate> templates,
  String? gender,
) {
  final copy = List<ConfiguratorTemplate>.from(templates);
  if (gender == null || !UserGenderPreference.all.contains(gender)) {
    copy.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return copy;
  }
  copy.sort((a, b) {
    final aMatch = configuratorTemplateMatchesGender(a, gender);
    final bMatch = configuratorTemplateMatchesGender(b, gender);
    if (aMatch != bMatch) return aMatch ? -1 : 1;
    return a.sortOrder.compareTo(b.sortOrder);
  });
  return copy;
}

/// Default template when opening the build tab for [gender].
ConfiguratorTemplate? preferredConfiguratorTemplateForGender(
  List<ConfiguratorTemplate> templates,
  String? gender,
) {
  if (templates.isEmpty) return null;
  final sorted = sortConfiguratorTemplatesForGender(templates, gender);
  if (gender != null && UserGenderPreference.all.contains(gender)) {
    for (final t in sorted) {
      if (configuratorTemplateMatchesGender(t, gender)) return t;
    }
  }
  for (final t in sorted) {
    if (t.id == kDefaultConfiguratorTemplateId) return t;
  }
  return sorted.first;
}
