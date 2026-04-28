import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/features/admin/data/admin_repository.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';

/// Shared admin repository.
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Users list, optionally filtered by role/banned/search.
final adminUsersProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, AdminUsersFilter>((ref, filter) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.listUsers(
    role: filter.role,
    banned: filter.banned,
    search: filter.search,
  );
  return result.fold<List<Map<String, dynamic>>>(
    (e) => throw AdminProviderException(e),
    (list) => list,
  );
});

/// Orders list with optional status filter.
final adminOrdersProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, status) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.listOrders(status: status);
  return result.fold<List<Map<String, dynamic>>>(
    (e) => throw AdminProviderException(e),
    (list) => list,
  );
});

/// Commission/payout list with optional status filter.
final adminPayoutsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, status) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.listPayouts(status: status);
  return result.fold<List<Map<String, dynamic>>>(
    (e) => throw AdminProviderException(e),
    (list) => list,
  );
});

/// Complaints list with optional status filter.
final adminComplaintsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, status) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.listComplaints(status: status);
  return result.fold<List<Map<String, dynamic>>>(
    (e) => throw AdminProviderException(e),
    (list) => list,
  );
});

/// Partner role request queue (optional [status]: pending, approved, rejected).
final adminRoleRequestsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, status) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.listRoleRequests(status: status);
  return result.fold<List<Map<String, dynamic>>>(
    (e) => throw AdminProviderException(e),
    (list) => list,
  );
});

/// CMS resource listing (mannequins/fabrics/patterns/presets).
final adminCmsListProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, resource) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.listCms(resource);
  return result.fold<List<Map<String, dynamic>>>(
    (e) => throw AdminProviderException(e),
    (list) => list,
  );
});

/// Dashboard summary counts.
final adminStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.stats();
  return result.fold<Map<String, dynamic>>(
    (e) => throw AdminProviderException(e),
    (stats) => stats,
  );
});

/// Filter for [adminUsersProvider].
@immutable
class AdminUsersFilter {
  /// Creates a user filter.
  const AdminUsersFilter({this.role, this.banned, this.search});

  /// Optional role filter (e.g. `tailor`, `delivery`).
  final String? role;

  /// When set, filters banned (true) or active (false) users.
  final bool? banned;

  /// Free-text name/email search.
  final String? search;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminUsersFilter &&
        other.role == role &&
        other.banned == banned &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(role, banned, search);
}

/// User-facing text for [AsyncValue] / admin Future errors.
String formatAdminProviderError(Object error) {
  if (error is AdminProviderException) {
    return mapAppExceptionMessage(
      error.cause,
      fallback: 'Could not load this section. Please try again.',
      networkMessage: 'Network issue. Check your connection and try again.',
      authMessage: 'Session expired or you do not have access. Sign in again.',
    );
  }
  return error.toString();
}

/// Wrapper so async errors surface as typed exceptions.
class AdminProviderException implements Exception {
  /// Creates a wrapper around [cause].
  const AdminProviderException(this.cause);

  /// Original domain exception.
  final AppException cause;
}
