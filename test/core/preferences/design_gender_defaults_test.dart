import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/preferences/design_gender_defaults.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/editor/data/built_in_mannequin_assets.dart';

void main() {
  test('mannequin defaults follow gender lane', () {
    expect(
      mannequinIdForGender(UserGenderPreference.women),
      kPresetCatalogMannequinId,
    );
    expect(mannequinIdForGender(UserGenderPreference.men), 'standard_male');
  });

  test('garment types differ for men and women', () {
    final men = garmentTypesForGender(UserGenderPreference.men)
        .map((e) => e.$2)
        .toList();
    final women = garmentTypesForGender(UserGenderPreference.women)
        .map((e) => e.$2)
        .toList();
    expect(men, contains('thobe'));
    expect(women, contains('abaya'));
    expect(women, isNot(contains('thobe')));
  });
}
