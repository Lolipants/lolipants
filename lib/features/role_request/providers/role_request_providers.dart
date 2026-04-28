import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/role_request/data/role_request_repository.dart';

/// Role request API for the customer app.
final roleRequestRepositoryProvider = Provider<RoleRequestRepository>(
  (ref) => RoleRequestRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Current user’s role request history (newest first).
final myRoleRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(roleRequestRepositoryProvider);
  final result = await repo.listMine();
  return result.fold(
    (e) => throw e,
    (list) => list,
  );
});
