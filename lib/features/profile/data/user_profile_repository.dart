import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';

/// Reads and updates shopper profile fields on [lolipants-api] D1.
class UserProfileRepository {
  /// Creates the repository.
  UserProfileRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Returns gender from `GET /users/me`, or null when unset / unavailable.
  Future<Either<AppException, String?>> fetchGender() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.users}/me',
      );
      final data = response.data;
      if (data == null) {
        return right(null);
      }
      final raw = data['gender']?.toString().trim().toLowerCase();
      if (raw == null || raw.isEmpty) {
        return right(null);
      }
      return right(raw);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Persists gender via `PATCH /users/me`.
  Future<Either<AppException, String>> updateGender(String gender) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '${ApiEndpoints.users}/me',
        data: {'gender': gender.trim().toLowerCase()},
      );
      final saved = response.data?['gender']?.toString().trim().toLowerCase();
      if (saved == null || saved.isEmpty) {
        return left(const ServerException(500, 'Gender not saved'));
      }
      return right(saved);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final body = e.response?.data;
    var message = e.message ?? 'network';
    if (body is Map && body['error'] != null) {
      message = body['error'].toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException(message);
    }
    if (status == 401 || status == 403) return AuthException(message);
    if (status >= 500) return ServerException(status, message);
    if (status >= 400) return ServerException(status, message);
    return NetworkException(message);
  }
}
