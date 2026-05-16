import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/orders/models/order_quote.dart';

/// API-backed repository for customer orders.
class OrdersRepository {
  /// Creates the repository.
  OrdersRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Loads all orders for the current authenticated user.
  Future<Either<AppException, List<Order>>> getMyOrders() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.orders,
        options: await _authOptions(),
      );
      final items = response.data ?? const <dynamic>[];
      final orders = items
          .whereType<Map<String, dynamic>>()
          .map(Order.fromApi)
          .toList(growable: false);
      return right(orders);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Loads a single order by id.
  Future<Either<AppException, Order>> getOrderById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.orders}/$id',
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing order payload'));
      }
      return right(Order.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Cancels a customer order.
  Future<Either<AppException, void>> cancelOrder(String id) async {
    try {
      await _dio.delete<void>(
        '${ApiEndpoints.orders}/$id',
        options: await _authOptions(),
      );
      return right(null);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Fetches a server-authoritative price quote for [designId] at delivery coords.
  Future<Either<AppException, OrderQuote>> getQuote({
    required String designId,
    required String city,
    required double deliveryLat,
    required double deliveryLng,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.orders}/quote',
        queryParameters: {
          'designId': designId,
          'city': city,
          'deliveryLat': deliveryLat,
          'deliveryLng': deliveryLng,
        },
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing quote payload'));
      }
      return right(OrderQuote.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Creates a customer order from a saved design.
  ///
  /// Pass [idempotencyKey] to share the same key across retries or sibling
  /// requests (e.g. payment intent). When omitted a new key is generated.
  Future<Either<AppException, Order>> createOrder({
    required String designId,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryPhone,
    required double deliveryLat,
    required double deliveryLng,
    required String tailorId,
    required int basePrice,
    required int fabricFee,
    required int deliveryFee,
    required int totalPrice,
    String? deliveryNotes,
    String? idempotencyKey,
    String? designerId,
  }) async {
    try {
      final key = idempotencyKey ??
          'order_${DateTime.now().millisecondsSinceEpoch}_$designId';
      final authOptions = await _authOptions();
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.orders,
        data: {
          'designId': designId,
          'deliveryAddress': deliveryAddress,
          'deliveryCity': deliveryCity,
          'deliveryPhone': deliveryPhone,
          'deliveryLat': deliveryLat,
          'deliveryLng': deliveryLng,
          'tailorId': tailorId,
          'basePrice': basePrice,
          'fabricFee': fabricFee,
          'deliveryFee': deliveryFee,
          'totalPrice': totalPrice,
          'deliveryNotes': deliveryNotes,
          if (designerId != null && designerId.isNotEmpty)
            'designerId': designerId,
        },
        options: authOptions.copyWith(
          headers: {
            ...?(authOptions.headers),
            'X-Idempotency-Key': key,
          },
        ),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing order payload'));
      }
      return right(Order.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Options> _authOptions() async {
    final headers = <String, dynamic>{};
    final token = await _storage.readSessionToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return Options(headers: headers);
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final body = e.response?.data;
    var message = e.message ?? 'network';
    if (body is Map) {
      final nestedError = body['error'];
      if (nestedError is Map && nestedError['message'] != null) {
        message = nestedError['message'].toString();
      } else if (body['error'] != null) {
        message = body['error'].toString();
      } else if (body['message'] != null) {
        message = body['message'].toString();
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException(message);
    }
    if (status == 401 || status == 403) {
      return AuthException(message);
    }
    if (status >= 500) {
      return ServerException(status, message);
    }
    if (status >= 400) {
      return ServerException(status, message);
    }
    return NetworkException(message);
  }
}
