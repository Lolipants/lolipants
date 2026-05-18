import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/wedding/data/wedding_repository.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';

final weddingRepositoryProvider = Provider<WeddingRepository>((ref) {
  return WeddingRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  );
});

final weddingDressesProvider =
    FutureProvider.family<List<WeddingDress>, WeddingCategoryFilter>(
  (ref, filter) async {
    final repo = ref.watch(weddingRepositoryProvider);
    final result = await repo.listDresses(filter: filter);
    return result.fold((_) => <WeddingDress>[], (list) => list);
  },
);
