import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

void main() {
  test('setCatalogDesignPath keeps selection after mannequin sync', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const pathA =
        'assets/images/designs/design_womens_look_lev_kaftan_aubergine.png';
    const pathB =
        'assets/images/designs/design_womens_look_gulf_abaya_black.png';
    final notifier = container.read(editorProvider.notifier);
    notifier.state = EditorState.initial().copyWith(
      buildStyleMode: EditorBuildStyleMode.catalog,
      selectedCatalogDesignPath: pathA,
      mannequinId: 'standard_female',
    );

    notifier.setCatalogDesignPath(pathB);
    notifier.syncBuildLaneForMannequin([
      const ConfiguratorTemplate(
        id: 'modest_abaya',
        nameEn: 'Modest abaya',
        nameAr: 'عباية',
        garmentType: 'abaya',
        regionTag: 'gulf',
        sortOrder: 0,
        requiredSlotKeys: const [],
        slots: const [],
      ),
    ]);

    final editor = container.read(editorProvider);
    expect(editor.buildStyleMode, EditorBuildStyleMode.catalog);
    expect(editor.selectedCatalogDesignPath, pathB);
    expect(editor.preferCatalogBuild, isFalse);
    expect(editor.pinnedBrowseCatalogPath, isNull);
  });

  test('catalog bootstrap path selection does not set persistent pin flags', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const path =
        'assets/images/designs/design_womens_look_lev_kaftan_aubergine.png';
    final notifier = container.read(editorProvider.notifier);
    notifier.beginNewDesign(mannequinId: 'standard_female');
    notifier.setCatalogDesignPath(path);

    expect(container.read(editorProvider).selectedCatalogDesignPath, path);
    expect(container.read(editorProvider).preferCatalogBuild, isFalse);
    expect(container.read(editorProvider).pinnedBrowseCatalogPath, isNull);
  });
}
