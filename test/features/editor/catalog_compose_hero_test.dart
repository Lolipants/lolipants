import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/logic/catalog_compose_hero.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

void main() {
  test('catalog compose hero only in design-catalogue build mode', () {
    final configurator = EditorState.initial().copyWith(
      buildStyleMode: EditorBuildStyleMode.configurator,
      selectedCatalogDesignPath: kDefaultCatalogDesignPath,
      heroMode: EditorHeroMode.compose,
    );
    expect(showsCatalogComposeHero(configurator), isFalse);

    final catalog = configurator.copyWith(
      buildStyleMode: EditorBuildStyleMode.catalog,
    );
    expect(showsCatalogComposeHero(catalog), isTrue);
  });
}
