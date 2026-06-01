import 'package:flutter_test/flutter_test.dart';

import 'package:lolipants/core/preferences/user_gender_provider.dart';

import 'package:lolipants/features/editor/data/bundled_design_assets.dart';

import 'package:lolipants/features/editor/logic/catalog_design_gender_filter.dart';



void main() {

  test('filters catalog paths for female mannequin', () {

    final paths = catalogDesignPathsForMannequin('petite_female');

    expect(paths, isNotEmpty);

    expect(

      paths.any((p) => p.contains('design_womens_look_mod_abaya_plum_satin')),

      isTrue,

    );

    expect(

      paths.any((p) => p.contains('design_mens_look_gulf_thobe_sky_blue')),

      isFalse,

    );

    expect(

      paths.any((p) => p.contains('design_casual_tee_crew_white')),

      isTrue,

    );

  });



  test('filters catalog paths for male mannequin', () {

    final paths = catalogDesignPathsForMannequin('standard_male');

    expect(paths, isNotEmpty);

    expect(

      paths.any((p) => p.contains('design_mens_look_gulf_thobe_sky_blue')),

      isTrue,

    );

    expect(

      paths.any((p) => p.contains('design_womens_look_mod_abaya_plum_satin')),

      isFalse,

    );

    expect(

      paths.any((p) => p.contains('design_casual_tee_crew_white')),

      isTrue,

    );

  });



  test('catalogDesignPathMatchesGenderLane respects gender lanes', () {

    expect(

      catalogDesignPathMatchesGenderLane(

        'assets/images/designs/design_womens_look_mod_abaya_plum_satin.png',

        UserGenderPreference.women,

      ),

      isTrue,

    );

    expect(

      catalogDesignPathMatchesGenderLane(

        'assets/images/designs/design_womens_look_mod_abaya_plum_satin.png',

        UserGenderPreference.men,

      ),

      isFalse,

    );

    expect(

      catalogDesignPathMatchesGenderLane(

        'assets/images/designs/design_casual_tee_crew_white.png',

        UserGenderPreference.men,

      ),

      isTrue,

    );

    expect(

      catalogDesignPathMatchesGenderLane(

        'assets/images/designs/design_casual_tee_crew_white.png',

        UserGenderPreference.women,

      ),

      isTrue,

    );

  });



  test('traditional filter shows gulf thobes for men only', () {

    final sections = bundledCatalogSectionsForMannequin(

      'standard_male',

      catalogFilter: DesignCatalogFilter.traditional,

    );

    final paths = sections.expand((s) => s.$2.map((p) => p.ref)).toList();

    expect(

      paths.any((p) => p.contains('design_mens_look_gulf_thobe_sky_blue')),

      isTrue,

    );

    expect(

      paths.any((p) => p.contains('design_womens_look_gulf_abaya')),

      isFalse,

    );

  });



  test('modern filter shows gender-appropriate looks', () {

    final women = bundledCatalogSectionsForMannequin(

      'petite_female',

      catalogFilter: DesignCatalogFilter.modern,

    );

    final men = bundledCatalogSectionsForMannequin(

      'standard_male',

      catalogFilter: DesignCatalogFilter.modern,

    );

    expect(

      women.expand((s) => s.$2).any(

        (p) => p.ref.contains('design_womens_look_mod_abaya_plum_satin'),

      ),

      isTrue,

    );

    expect(

      men.expand((s) => s.$2).any(

        (p) => p.ref.contains('design_mens_look_mod_mens_anorak_sand'),

      ),

      isTrue,

    );

  });



  test('bundled catalogue lists every shipped design asset once', () {

    final listed = kBundledDesignCatalog

        .expand((s) => s.$2)

        .toSet();

    expect(listed.length, 74);

  });

}

