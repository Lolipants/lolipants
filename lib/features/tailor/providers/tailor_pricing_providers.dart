import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/tailor/data/tailor_pricing_repository.dart';
import 'package:lolipants/features/tailor/models/tailor_pricing_catalog.dart';

final tailorPricingRepositoryProvider = Provider<TailorPricingRepository>(
  (ref) => TailorPricingRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

final tailorPricingCatalogProvider =
    AsyncNotifierProvider<TailorPricingCatalogNotifier, TailorPricingCatalog>(
  TailorPricingCatalogNotifier.new,
);

class TailorPricingCatalogNotifier extends AsyncNotifier<TailorPricingCatalog> {
  @override
  Future<TailorPricingCatalog> build() async {
    final repo = ref.read(tailorPricingRepositoryProvider);
    final result = await repo.getCatalog();
    return result.fold(
      (e) => throw e,
      (catalog) => catalog,
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(tailorPricingRepositoryProvider);
      final result = await repo.getCatalog();
      return result.fold(
        (e) => throw e,
        (catalog) => catalog,
      );
    });
  }
}
