import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/editor/logic/catalog_design_gender_filter.dart';

void main() {
  test('filters catalog paths for female mannequin', () {
    final paths = catalogDesignPathsForMannequin('petite_female');
    expect(paths, isNotEmpty);
    expect(
      paths.any((p) => p.contains('design_mod_abaya_plum_satin')),
      isTrue,
    );
    expect(
      paths.any((p) => p.contains('design_gulf_thobe_sky_blue')),
      isFalse,
    );
  });

  test('filters catalog paths for male mannequin', () {
    final paths = catalogDesignPathsForMannequin('standard_male');
    expect(paths, isNotEmpty);
    expect(
      paths.any((p) => p.contains('design_gulf_thobe_sky_blue')),
      isTrue,
    );
    expect(
      paths.any((p) => p.contains('design_mod_abaya_plum_satin')),
      isFalse,
    );
  });

  test('catalogDesignPathMatchesGenderLane respects gender lanes', () {
    expect(
      catalogDesignPathMatchesGenderLane(
        'assets/images/designs/design_mod_abaya_plum_satin.png',
        UserGenderPreference.women,
      ),
      isTrue,
    );
    expect(
      catalogDesignPathMatchesGenderLane(
        'assets/images/designs/design_mod_abaya_plum_satin.png',
        UserGenderPreference.men,
      ),
      isFalse,
    );
  });
}
