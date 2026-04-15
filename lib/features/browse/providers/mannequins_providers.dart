import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/browse/data/mannequins_repository.dart';
import 'package:lolipants/features/browse/models/mannequin_option.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';

final mannequinsRepositoryProvider = Provider<MannequinsRepository>(
  (ref) => MannequinsRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

final mannequinOptionsProvider =
    FutureProvider<List<MannequinOption>>((ref) async {
  final repo = ref.watch(mannequinsRepositoryProvider);
  final result = await repo.getMannequins();
  return result.fold((_) => const <MannequinOption>[], (list) => list);
});
