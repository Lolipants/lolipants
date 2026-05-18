import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/tailor/data/tailor_wedding_pricing_repository.dart';
import 'package:lolipants/features/tailor/models/tailor_wedding_pricing.dart';

final tailorWeddingPricingRepositoryProvider =
    Provider<TailorWeddingPricingRepository>((ref) {
  return TailorWeddingPricingRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  );
});

final tailorWeddingPricingProvider =
    FutureProvider<TailorWeddingPricingCatalog>((ref) async {
  final repo = ref.watch(tailorWeddingPricingRepositoryProvider);
  final result = await repo.getCatalog();
  return result.fold(
    (e) => throw e,
    (catalog) => catalog,
  );
});
