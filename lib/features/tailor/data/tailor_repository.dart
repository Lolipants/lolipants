import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/orders/models/order.dart';

/// Repository scoped to tailor-role actions on the orders API.
class TailorRepository {
  /// Creates the repository.
  TailorRepository({required Dio dio, required AuthLocalStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Fetches the tailor's work queue, optionally filtered by a comma-separated
  /// list of order statuses.
  Future<Either<AppException, List<Order>>> getQueue({
    List<String>? statuses,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiEndpoints.orders}/queue',
        queryParameters: statuses != null && statuses.isNotEmpty
            ? {'status': statuses.join(',')}
            : null,
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

  /// Claims an unassigned order for the current tailor.
  Future<Either<AppException, void>> claim(String orderId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.orders}/$orderId/claim',
        options: await _authOptions(),
      );
      return right(null);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Advances (or cancels) an order with the supplied [status].
  Future<Either<AppException, void>> advanceStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '${ApiEndpoints.orders}/$orderId/status',
        data: {'status': status, if (note != null) 'note': note},
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
    if (body is Map) {
      final nested = body['error'];
      if (nested is Map && nested['message'] != null) {
        message = nested['message'].toString();
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
    if (status == 401 || status == 403) return AuthException(message);
    if (status >= 400) return ServerException(status, message);
    return NetworkException(message);
  }
}
