import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/assets/catalog_image_uri.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: 'CLOUDFLARE_R2_BASE_URL=https://cdn.example.com\n',
    );
  });

  test('useRemoteCatalogAssets is true when R2 base is set', () {
    expect(useRemoteCatalogAssets, isTrue);
  });

  testWidgets('CatalogImage uses network image when R2 is configured', (
    tester,
  ) async {
    const path =
        'assets/images/designs/design_womens_look_gulf_abaya_black_closed.png';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatalogImage(
            path: path,
            width: 120,
            height: 160,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image.toString(), contains('cdn.example.com/catalog/designs/'));
    expect(image.image.toString(), contains('design_womens_look_gulf_abaya_black_closed'));
  });
}
