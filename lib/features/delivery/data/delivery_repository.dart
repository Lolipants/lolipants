import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/orders/models/order.dart';

/// Repository for the delivery-role courier endpoints exposed by
/// `lolipants-api/src/routes/delivery.ts`.
class DeliveryRepository {
  /// Creates the repository backed by [dio] and [storage].
  DeliveryRepository({required Dio dio, required AuthLocalStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Orders ready to pick up (status = ready_to_ship, unclaimed).
  Future<Either<AppException, List<Order>>> queue() => _list('/queue');

  /// Orders the current courier is actively delivering.
  Future<Either<AppException, List<Order>>> active() => _list('/active');

  /// Orders the current courier has completed.
  Future<Either<AppException, List<Order>>> history() => _list('/history');

  /// Single order (queue-pickup-ready or claimed by this courier).
  Future<Either<AppException, Order>> detail(String orderId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.delivery}/orders/$orderId',
        options: await _authOptions(),
      );
      final data = response.data ?? const <String, dynamic>{};
      return right(Order.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Claims [orderId] for this courier.
  Future<Either<AppException, void>> claim(String orderId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.delivery}/orders/$orderId/claim',
        options: await _authOptions(),
      );
      return right(null);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Marks the order as picked up / out for delivery.
  Future<Either<AppException, void>> markPickedUp(String orderId, {String? note}) {
    return _patchStatus(orderId, status: 'out_for_delivery', note: note);
  }

  /// Marks the order as delivered. Requires a [proofUrl] for the photo receipt.
  Future<Either<AppException, void>> markDelivered({
    required String orderId,
    required String proofUrl,
    String? note,
  }) {
    return _patchStatus(
      orderId,
      status: 'delivered',
      proofUrl: proofUrl,
      note: note,
    );
  }

  Future<Either<AppException, List<Order>>> _list(String path) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiEndpoints.delivery}$path',
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

  Future<Either<AppException, void>> _patchStatus(
    String orderId, {
    required String status,
    String? proofUrl,
    String? note,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '${ApiEndpoints.delivery}/orders/$orderId/status',
        data: {
          'status': status,
          if (proofUrl != null) 'proofUrl': proofUrl,
          if (note != null) 'note': note,
        },
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
