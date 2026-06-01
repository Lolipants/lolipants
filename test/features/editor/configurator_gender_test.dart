import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/models/mannequin_option.dart';
import 'package:lolipants/features/editor/logic/configurator_gender.dart';
import 'package:lolipants/features/editor/logic/mannequin_gender.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';

void main() {
  test('sortMannequinsForGender puts male first for men', () {
    const options = [
      MannequinOption(
        id: 'petite_female',
        labelEn: 'Petite (Female)',
        labelAr: 'f',
      ),
      MannequinOption(
        id: 'standard_male',
        labelEn: 'Standard (Male)',
        labelAr: 'm',
      ),
    ];
    final sorted = sortMannequinsForGender(options, UserGenderPreference.men);
    expect(sorted.first.id, 'standard_male');
  });

  test('sortConfiguratorTemplatesForGender puts abaya first for women', () {
    const templates = [
      ConfiguratorTemplate(
        id: 'western_dress_v1',
        nameEn: 'Western dress',
        nameAr: 'Western',
        garmentType: 'dress',
        regionTag: 'western',
        sortOrder: 1,
        requiredSlotKeys: [],
        slots: [],
      ),
      ConfiguratorTemplate(
        id: 'modest_abaya_v1',
        nameEn: 'Modest abaya',
        nameAr: 'Abaya',
        garmentType: 'abaya',
        regionTag: 'modest',
        sortOrder: 0,
        requiredSlotKeys: [],
        slots: [],
      ),
    ];
    final sorted = sortConfiguratorTemplatesForGender(
      templates,
      UserGenderPreference.women,
    );
    expect(sorted.first.id, 'modest_abaya_v1');
  });

  test('configuratorTemplatesForMannequin excludes women templates for male mannequin',
      () {
    const templates = [
      ConfiguratorTemplate(
        id: 'western_dress_v1',
        nameEn: 'Western dress',
        nameAr: 'Western',
        garmentType: 'dress',
        regionTag: 'western',
        sortOrder: 1,
        requiredSlotKeys: [],
        slots: [],
      ),
      ConfiguratorTemplate(
        id: 'modest_abaya_v1',
        nameEn: 'Modest abaya',
        nameAr: 'Abaya',
        garmentType: 'abaya',
        regionTag: 'modest',
        sortOrder: 0,
        requiredSlotKeys: [],
        slots: [],
      ),
    ];
    final male = configuratorTemplatesForMannequin(
      templates,
      'standard_male',
    );
    expect(male, isEmpty);
    expect(
      mannequinGenderLane('standard_male'),
      UserGenderPreference.men,
    );
    final female = configuratorTemplatesForMannequin(
      templates,
      'petite_female',
    );
    expect(female.length, 2);
  });
}
