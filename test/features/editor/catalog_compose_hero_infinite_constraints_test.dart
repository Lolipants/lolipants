import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/editor_catalog_compose_hero.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: 'CLOUDFLARE_R2_BASE_URL=https://cdn.example.com\n',
    );
  });

  testWidgets('EditorCatalogComposeHero uses finite size under infinite width', (
    tester,
  ) async {
    const path =
        'assets/images/designs/design_womens_look_gulf_abaya_cardigan_charcoal.png';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          designCatalogLookupProvider.overrideWithValue(const {}),
          editorProvider.overrideWith(
            (ref) => _SeedEditorNotifier(
              ref,
              EditorState.initial().copyWith(
                buildStyleMode: EditorBuildStyleMode.catalog,
                selectedCatalogDesignPath: path,
                heroMode: EditorHeroMode.compose,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 500,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: const EditorCatalogComposeHero(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final image = tester.widget<CatalogImage>(find.byType(CatalogImage));
    expect(image.width!.isFinite, isTrue);
    expect(image.height!.isFinite, isTrue);
    expect(image.width, greaterThan(0));
    expect(image.height, greaterThan(0));
  });
}

class _SeedEditorNotifier extends EditorNotifier {
  _SeedEditorNotifier(Ref ref, EditorState seed) : super(ref) {
    state = seed;
  }
}
