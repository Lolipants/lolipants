import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/core/network/dio_client.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/orders/data/orders_repository.dart';
import 'package:lolipants/features/orders/models/order.dart';

/// Shared app API dio instance.
final apiDioProvider = Provider<Dio>((ref) => DioClient.create());

/// Orders repository wired to API dio + secure token storage.
final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Orders list state source for the orders screen.
final myOrdersProvider =
    AsyncNotifierProvider<MyOrdersNotifier, List<Order>>(MyOrdersNotifier.new);

/// Single order provider for detail screen.
final orderByIdProvider =
    FutureProvider.family<Order, String>((ref, orderId) async {
  final repo = ref.watch(ordersRepositoryProvider);
  final result = await repo.getOrderById(orderId);
  return result.fold<Order>(
    (e) => throw OrdersProviderException(e),
    (order) => order,
  );
});

/// Loads and refreshes current user's orders.
class MyOrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    final repo = ref.read(ordersRepositoryProvider);
    final result = await repo.getMyOrders();
    return result.fold<List<Order>>(
      (e) => throw OrdersProviderException(e),
      (orders) => orders,
    );
  }

  /// Manual refresh used by pull-to-refresh and retry actions.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(ordersRepositoryProvider);
      final result = await repo.getMyOrders();
      return result.fold<List<Order>>(
        (e) => throw OrdersProviderException(e),
        (orders) => orders,
      );
    });
  }

  /// Cancels an order and reloads the list.
  Future<void> cancel(String orderId) async {
    final repo = ref.read(ordersRepositoryProvider);
    final result = await repo.cancelOrder(orderId);
    result.fold<void>(
      (e) => throw OrdersProviderException(e),
      (_) {},
    );
    await reload();
  }
}

/// Exception wrapper so Riverpod async providers throw proper exceptions.
class OrdersProviderException implements Exception {
  /// Creates a wrapper around [cause].
  const OrdersProviderException(this.cause);

  /// Original domain exception.
  final AppException cause;
}

/// Human-friendly message for order-related async errors.
String orderErrorMessage(
  Object error, {
  String fallback = 'Something went wrong with orders.',
}) {
  final appError = switch (error) {
    OrdersProviderException(cause: final cause) => cause,
    AppException() => error,
    _ => null,
  };
  if (appError == null) return fallback;
  if (appError case ServerException(statusCode: 404, message: final msg)
      when msg.toLowerCase().contains('design')) {
    return 'The selected design was not found. '
        'Please create or choose another design.';
  }
  if (appError case ServerException(statusCode: 400, message: final msg)
      when msg.toLowerCase().contains('cancel')) {
    return 'This order can no longer be cancelled.';
  }
  return mapAppExceptionMessage(
    appError,
    fallback: fallback,
    networkMessage:
        'Network issue while contacting orders service. Please retry.',
    authMessage: 'Your session has expired. Please sign in again.',
    statusMessages: const {
      403: 'You do not have permission for this order action.',
      404: 'The requested order could not be found.',
    },
  );
}
