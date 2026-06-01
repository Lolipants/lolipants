import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';

void main() {
  test('catalogDesignDisplayPath keeps bundled look paths on CDN', () {
    const look =
        'assets/images/designs/design_womens_look_mag_dress_takchita_inspired.png';
    expect(catalogDesignDisplayPath(look), look);
  });

  test('catalogFlatlayPathFor strips _look_ segment', () {
    expect(
      catalogFlatlayPathFor(
        'assets/images/designs/design_womens_look_mag_dress_takchita_inspired.png',
      ),
      'assets/images/designs/design_womens_mag_dress_takchita_inspired.png',
    );
    expect(
      catalogFlatlayPathFor(
        'assets/images/designs/design_mens_look_gulf_thobe_sky_blue.png',
      ),
      'assets/images/designs/design_mens_gulf_thobe_sky_blue.png',
    );
  });

  test('catalogFlatlayPathFor leaves casual flat-lays unchanged', () {
    const casual =
        'assets/images/designs/design_casual_tee_crew_white.png';
    expect(catalogFlatlayPathFor(casual), casual);
  });

  test('catalogLookRenderFallbackPath inverts flat-lay path', () {
    expect(
      catalogLookRenderFallbackPath(
        'assets/images/designs/design_womens_mag_dress_takchita_inspired.png',
      ),
      'assets/images/designs/design_womens_look_mag_dress_takchita_inspired.png',
    );
    expect(
      catalogLookRenderFallbackPath(
        'assets/images/designs/design_womens_look_mag_dress_takchita_inspired.png',
      ),
      isNull,
    );
  });
}
