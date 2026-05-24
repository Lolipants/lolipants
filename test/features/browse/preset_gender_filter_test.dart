import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/data/preset_gender_filter.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';

void main() {
  test('filters home catalog for men and women lanes', () {
    final pool = regionPresetsForHomeGrid();
    final men = filterPresetsForUserGender(pool, UserGenderPreference.men);
    final women = filterPresetsForUserGender(pool, UserGenderPreference.women);

    expect(men.any((p) => p.id == 'qa_thobe'), isTrue);
    expect(men.any((p) => p.id.startsWith('mens_')), isTrue);
    expect(men.any((p) => p.garmentType == 'dress'), isFalse);

    expect(women.any((p) => p.id == 'ma_djellaba'), isTrue);
    expect(women.any((p) => p.id == 'casual_denim'), isTrue);
    expect(women.any((p) => p.id.startsWith('mens_')), isFalse);
    expect(women.any((p) => p.id == 'qa_thobe'), isFalse);
  });

  test('returns full pool when gender is unset', () {
    final pool = regionPresetsForHomeGrid();
    expect(filterPresetsForUserGender(pool, null).length, pool.length);
  });
}
