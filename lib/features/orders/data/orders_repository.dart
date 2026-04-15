import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/orders/models/order.dart';

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
    if (body is Map && body['error'] != null) {
      message = body['error'].toString();
    } else if (body is Map && body['message'] != null) {
      message = body['message'].toString();
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
