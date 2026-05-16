import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/tailor/data/tailor_repository.dart';

/// Repository shared across tailor screens.
final tailorRepositoryProvider = Provider<TailorRepository>(
  (ref) => TailorRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Family key describing which bucket of the queue to load.
enum TailorQueueBucket {
  /// Placed / confirmed orders waiting to be worked on.
  incoming,

  /// In-progress orders.
  active,

  /// Terminal orders (delivered / cancelled).
  completed,
}

/// Maps a bucket to the list of backend status strings.
List<String> _statusesFor(TailorQueueBucket bucket) {
  switch (bucket) {
    case TailorQueueBucket.incoming:
      return const ['placed', 'confirmed'];
    case TailorQueueBucket.active:
      return const [
        'cutting',
        'stitching',
        'embroidery',
        'quality_check',
        'ready_to_ship',
        'out_for_delivery',
      ];
    case TailorQueueBucket.completed:
      return const ['delivered', 'cancelled'];
  }
}

/// Single order for tailor production view (includes print/sketch URLs).
final tailorOrderDetailProvider =
    FutureProvider.family<Order, String>((ref, orderId) async {
  final repo = ref.read(tailorRepositoryProvider);
  final result = await repo.getOrderDetail(orderId);
  return result.fold<Order>(
    (e) => throw TailorProviderException(e),
    (order) => order,
  );
});

/// Returns the queue for the given [bucket].
final tailorQueueProvider = AsyncNotifierProviderFamily<
    TailorQueueNotifier, List<Order>, TailorQueueBucket>(TailorQueueNotifier.new);

/// Notifier driving [tailorQueueProvider].
class TailorQueueNotifier
    extends FamilyAsyncNotifier<List<Order>, TailorQueueBucket> {
  late TailorQueueBucket _bucket;

  @override
  Future<List<Order>> build(TailorQueueBucket bucket) async {
    _bucket = bucket;
    final repo = ref.read(tailorRepositoryProvider);
    final result = await repo.getQueue(statuses: _statusesFor(bucket));
    return result.fold<List<Order>>(
      (e) => throw TailorProviderException(e),
      (orders) => orders,
    );
  }

  /// Refetches the current bucket.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(tailorRepositoryProvider);
      final result = await repo.getQueue(statuses: _statusesFor(_bucket));
      return result.fold<List<Order>>(
        (e) => throw TailorProviderException(e),
        (orders) => orders,
      );
    });
  }
}

/// Wrapper so async errors surface as typed exceptions.
class TailorProviderException implements Exception {
  /// Creates a wrapper around [cause].
  const TailorProviderException(this.cause);

  /// Original domain exception.
  final AppException cause;
}
