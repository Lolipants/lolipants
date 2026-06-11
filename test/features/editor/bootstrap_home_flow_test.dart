import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/home/models/home_flow_selection.dart';

void main() {
  test('bootstrapHomeFlow designYourself opens configurator lane', () {
    final container = ProviderContainer(
      overrides: [
        designCatalogLookupProvider.overrideWithValue(const {}),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(editorProvider.notifier);
    notifier.bootstrapHomeFlow(
      serviceType: HomeServiceType.designYourself,
      styleLane: HomeStyleLane.modern,
      mannequinId: 'petite_female',
    );

    final state = container.read(editorProvider);
    expect(state.buildStyleMode, EditorBuildStyleMode.configurator);
    expect(state.preferCatalogBuild, isFalse);
  });

  test('bootstrapHomeFlow finishProduct opens design catalogue lane', () {
    final container = ProviderContainer(
      overrides: [
        designCatalogLookupProvider.overrideWithValue(const {}),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(editorProvider.notifier);
    notifier.bootstrapHomeFlow(
      serviceType: HomeServiceType.finishProduct,
      styleLane: HomeStyleLane.traditional,
      mannequinId: 'petite_female',
    );

    final state = container.read(editorProvider);
    expect(state.buildStyleMode, EditorBuildStyleMode.catalog);
    expect(state.catalogFilter, DesignCatalogFilter.traditional);
  });

  test('bootstrapHomeFlow finishProduct modern uses modern catalogue filter', () {
    final container = ProviderContainer(
      overrides: [
        designCatalogLookupProvider.overrideWithValue(const {}),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(editorProvider.notifier);
    notifier.bootstrapHomeFlow(
      serviceType: HomeServiceType.finishProduct,
      styleLane: HomeStyleLane.modern,
      mannequinId: 'standard_female',
    );

    expect(
      container.read(editorProvider).catalogFilter,
      DesignCatalogFilter.modern,
    );
  });
}
