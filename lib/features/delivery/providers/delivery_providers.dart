import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/delivery/data/delivery_repository.dart';
import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';

/// Shared repository for the three delivery queues and the detail screen.
final deliveryRepositoryProvider = Provider<DeliveryRepository>(
  (ref) => DeliveryRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Three buckets exposed by the delivery shell.
enum DeliveryQueueBucket {
  /// Orders ready for courier pickup.
  queue,

  /// Orders this courier is actively delivering.
  active,

  /// Orders this courier has already delivered.
  history,
}

/// Async list of orders for each bucket.
final deliveryQueueProvider = AsyncNotifierProviderFamily<
    DeliveryQueueNotifier, List<Order>, DeliveryQueueBucket>(
  DeliveryQueueNotifier.new,
);

/// Riverpod notifier driving [deliveryQueueProvider].
class DeliveryQueueNotifier
    extends FamilyAsyncNotifier<List<Order>, DeliveryQueueBucket> {
  late DeliveryQueueBucket _bucket;

  @override
  Future<List<Order>> build(DeliveryQueueBucket bucket) async {
    _bucket = bucket;
    return _fetch();
  }

  /// Refetches the current bucket.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<Order>> _fetch() async {
    final repo = ref.read(deliveryRepositoryProvider);
    final result = await _select(repo, _bucket);
    return result.fold<List<Order>>(
      (e) => throw DeliveryProviderException(e),
      (orders) => orders,
    );
  }

  Future<Either<AppException, List<Order>>> _select(
    DeliveryRepository repo,
    DeliveryQueueBucket bucket,
  ) {
    switch (bucket) {
      case DeliveryQueueBucket.queue:
        return repo.queue();
      case DeliveryQueueBucket.active:
        return repo.active();
      case DeliveryQueueBucket.history:
        return repo.history();
    }
  }
}

/// One-shot detail lookup for the courier-scoped delivery detail screen.
final deliveryOrderProvider =
    FutureProvider.family.autoDispose<Order, String>((ref, orderId) async {
  final repo = ref.watch(deliveryRepositoryProvider);
  final result = await repo.detail(orderId);
  return result.fold<Order>(
    (e) => throw DeliveryProviderException(e),
    (order) => order,
  );
});

/// Typed wrapper around [AppException] raised by delivery providers.
class DeliveryProviderException implements Exception {
  /// Creates a wrapper around [cause].
  const DeliveryProviderException(this.cause);

  /// Original domain exception.
  final AppException cause;
}
