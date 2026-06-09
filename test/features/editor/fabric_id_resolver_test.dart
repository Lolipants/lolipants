import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/utils/fabric_id_resolver.dart';

void main() {
  const showcaseIds = [
    'showcase_floral_blue_vintage',
    'showcase_floral_grey_stipple',
  ];

  test('keeps valid catalogue id', () {
    expect(
      resolveFabricIdToken('showcase_floral_blue_vintage', showcaseIds),
      'showcase_floral_blue_vintage',
    );
  });

  test('maps silk alias to first fabric when silk id absent', () {
    expect(
      resolveFabricIdToken('silk', showcaseIds),
      showcaseIds.first,
    );
  });

  test('falls back to first fabric for unknown AI token', () {
    expect(
      resolveFabricIdToken('mystery-fabric', showcaseIds),
      showcaseIds.first,
    );
  });

  test('falls back to first fabric when AI omits fabricId', () {
    expect(resolveFabricIdToken(null, showcaseIds), showcaseIds.first);
  });
}
