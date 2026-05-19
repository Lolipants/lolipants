import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/assets/catalog_image_uri.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: 'CLOUDFLARE_R2_BASE_URL=https://cdn.example.com\n',
    );
  });

  test('maps catalogue asset paths to R2 catalog prefix', () {
    expect(
      resolveCatalogImageUri(
        'assets/images/designs/design_gulf_abaya_black_closed.png',
      ),
      'https://cdn.example.com/catalog/designs/design_gulf_abaya_black_closed.png',
    );
    expect(
      resolveCatalogImageUri('assets/images/mannequins/standard_female.png'),
      'https://cdn.example.com/catalog/mannequins/standard_female.png',
    );
  });

  test('leaves http URLs unchanged', () {
    const url = 'https://other.example/photo.png';
    expect(resolveCatalogImageUri(url), url);
  });

  test('isCatalogAssetPath identifies catalogue folders', () {
    expect(
      isCatalogAssetPath('assets/images/designs/foo.png'),
      isTrue,
    );
    expect(
      isCatalogAssetPath('assets/images/lolipants_bg.png'),
      isFalse,
    );
  });
}
