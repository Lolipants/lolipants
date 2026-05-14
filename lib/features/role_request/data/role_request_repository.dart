import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';

/// API client for customer tailor/delivery role requests.
class RoleRequestRepository {
  /// Creates the repository.
  RoleRequestRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Submits a new role request.
  Future<Either<AppException, Map<String, dynamic>>> createRequest({
    required String requestedRole,
    String? message,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.roleRequests,
        data: {
          'requestedRole': requestedRole,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        },
        options: await _authOptions(),
      );
      return right(response.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Lists the signed-in user’s past requests.
  Future<Either<AppException, List<Map<String, dynamic>>>> listMine() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiEndpoints.roleRequests}/mine',
        options: await _authOptions(),
      );
      final items = response.data ?? const <dynamic>[];
      return right(
        items.whereType<Map<String, dynamic>>().toList(growable: false),
      );
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
