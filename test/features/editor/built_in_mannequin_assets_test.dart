import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/data/built_in_mannequin_assets.dart';

void main() {
  test('v1 catalogue exposes four mannequins only', () {
    expect(kVersionMannequinCatalog.length, 4);
    expect(
      kVersionMannequinCatalog.map((m) => m.id).toList(),
      ['petite_female', 'standard_female', 'standard_male', 'slim_male'],
    );
  });

  test('each v1 mannequin resolves to a bundled asset path', () {
    for (final m in kVersionMannequinCatalog) {
      expect(builtInMannequinAssetPath(m.id), m.assetPath);
    }
  });

  test('legacy female ids map to standard female asset', () {
    expect(
      builtInMannequinAssetPath('athletic_female'),
      kVersionMannequinCatalog[1].assetPath,
    );
  });
}
