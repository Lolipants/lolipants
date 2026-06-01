import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/design_flatlay_compose.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: 'CLOUDFLARE_R2_BASE_URL=https://cdn.example.com\n',
    );
  });

  testWidgets('DesignFlatlayCompose gives CatalogImage explicit hero dimensions', (
    tester,
  ) async {
    const path =
        'assets/images/designs/design_womens_look_gulf_abaya_cardigan_charcoal.png';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          designCatalogLookupProvider.overrideWithValue(const {}),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 480,
              child: DesignFlatlayCompose(
                designAssetPath: path,
                state: EditorState.initial().copyWith(
                  selectedCatalogDesignPath: path,
                  buildStyleMode: EditorBuildStyleMode.catalog,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CatalogImage), findsOneWidget);
    final image = tester.widget<CatalogImage>(find.byType(CatalogImage));
    expect(image.width, 320);
    expect(image.height, 480);
    expect(image.path, path);
  });

  testWidgets('DesignFlatlayCompose falls back when maxWidth is zero', (
    tester,
  ) async {
    const path =
        'assets/images/designs/design_womens_look_gulf_abaya_black_closed.png';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          designCatalogLookupProvider.overrideWithValue(const {}),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: DesignFlatlayCompose(
                designAssetPath: path,
                state: EditorState.initial().copyWith(
                  selectedCatalogDesignPath: path,
                  buildStyleMode: EditorBuildStyleMode.catalog,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CatalogImage), findsOneWidget);
    final image = tester.widget<CatalogImage>(find.byType(CatalogImage));
    expect(image.width, greaterThan(0));
    expect(image.height, 400);
  });
}
