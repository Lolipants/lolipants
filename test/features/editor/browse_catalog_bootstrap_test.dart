import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

void main() {
  test('syncBuildLaneForMannequin respects pinned browse catalogue design', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const path =
        'assets/images/designs/design_womens_look_lev_kaftan_aubergine.png';
    final notifier = container.read(editorProvider.notifier);
    notifier.state = EditorState.initial().copyWith(
      preferCatalogBuild: true,
      pinnedBrowseCatalogPath: path,
      buildStyleMode: EditorBuildStyleMode.catalog,
      selectedCatalogDesignPath: path,
      mannequinId: 'standard_female',
    );

    notifier.syncBuildLaneForMannequin([
      const ConfiguratorTemplate(
        id: 'modest_abaya',
        nameEn: 'Modest abaya',
        nameAr: 'عباية',
        garmentType: 'abaya',
        regionTag: 'gulf',
        sortOrder: 0,
        requiredSlotKeys: const [],
        slots: [],
      ),
    ]);

    final editor = container.read(editorProvider);
    expect(editor.buildStyleMode, EditorBuildStyleMode.catalog);
    expect(editor.selectedCatalogDesignPath, path);
    expect(editor.configuratorTemplateId, isEmpty);
  });
}
