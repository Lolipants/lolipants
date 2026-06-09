import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/core/network/dio_client.dart';
import 'package:lolipants/core/router/app_router.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/orders/data/orders_repository.dart';
import 'package:lolipants/features/orders/data/payments_repository.dart';
import 'package:lolipants/features/orders/models/order.dart';

/// Shared app API dio instance.
final apiDioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(authLocalStorageProvider);
  return DioClient.create(
    readSessionToken: storage.readSessionToken,
    onUnauthorized: () async {
      // A 401 while already unauthenticated (e.g. during sign-up) is
      // expected — only treat it as session expiry when there is an
      // active authenticated session.
      if (ref.read(authProvider).value is! AuthAuthenticated) return;
      // Suppress during post-auth init (e.g. GET /users/me 401 for a
      // brand-new account that has no profile row yet).
      if (ref.read(authProvider.notifier).isPostAuthInit) return;

      final context = rootNavigatorKey.currentContext;
      final router = ref.read(appRouterProvider);
      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      await ref
          .read(authProvider.notifier)
          .handleUnauthorized(returnTo: location);
      if (context != null && context.mounted) {
        context.go('/login');
      }
    },
  );
});

/// Orders repository wired to API dio + secure token storage.
final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Payments repository shares the same Dio + secure storage.
final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => PaymentsRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Polling interval for [watchOrderProvider]. Exposed for tests to override.
final orderPollingIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 60),
);

/// Live order stream that refetches every [orderPollingIntervalProvider]
/// while any listener is active. Cancels the timer on dispose.
final watchOrderProvider =
    StreamProvider.autoDispose.family<Order, String>((ref, orderId) {
  final controller = StreamController<Order>();
  final interval = ref.watch(orderPollingIntervalProvider);

  Future<void> fetch() async {
    final repo = ref.read(ordersRepositoryProvider);
    final result = await repo.getOrderById(orderId);
    if (controller.isClosed) return;
    result.fold(
      (e) => controller.addError(OrdersProviderException(e)),
      controller.add,
    );
  }

  fetch();
  final timer = Timer.periodic(interval, (_) => fetch());
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

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
  if (appError case ServerException(
        statusCode: 404,
        code: 'NO_TAILOR_AVAILABLE',
      )) {
    return 'No tailor is available for this design and delivery area. '
        'Try another address or ask support to enable tailor coverage.';
  }
  if (appError case ServerException(statusCode: 404, message: final msg)
      when msg.toLowerCase().contains('design')) {
    return 'The selected design was not found. '
        'Please save your design and try checkout again.';
  }
  if (appError case ServerException(statusCode: 404, message: final msg)
      when msg.toLowerCase().contains('tailor') ||
          msg.toLowerCase().contains('garment')) {
    return msg;
  }
  if (appError case ServerException(statusCode: 400, message: final msg)
      when msg.toLowerCase().contains('cancel')) {
    return 'This order can no longer be cancelled.';
  }
  if (appError case ServerException(
        code: 'ORDER_CREATE_FAILED',
        message: final msg,
      )) {
    return msg.trim().isNotEmpty
        ? msg
        : 'The server could not save your order before payment was attempted. '
            'Please try again in a moment.';
  }
  if (appError case ServerException(
        code: 'QUOTE_MISMATCH',
        message: final msg,
      )) {
    return msg;
  }
  if (appError case ServerException(
        code: 'MEASUREMENTS_REQUIRED',
        message: final msg,
      )) {
    return msg;
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
