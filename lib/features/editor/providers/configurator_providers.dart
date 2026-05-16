import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/editor/data/configurator_bundled_catalog.dart';
import 'package:lolipants/features/editor/data/configurator_repository.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';

final configuratorRepositoryProvider = Provider<ConfiguratorRepository>(
  (ref) => ConfiguratorRepository(dio: ref.watch(apiDioProvider)),
);

final configuratorCatalogProvider = FutureProvider<ConfiguratorCatalog>((ref) async {
  final repo = ref.watch(configuratorRepositoryProvider);
  final result = await repo.fetchCatalog();
  return result.fold(
    (_) => bundledConfiguratorCatalog(),
    (catalog) => catalog.templates.isEmpty
        ? bundledConfiguratorCatalog()
        : mergeConfiguratorCatalog(catalog),
  );
});
