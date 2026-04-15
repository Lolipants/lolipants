import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/sizing/models/body_measurements.dart';

/// API repository for measurements and workshop bookings.
class SizingRepository {
  /// Creates repository instance.
  SizingRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Gets the current user's latest measurements.
  Future<Either<AppException, BodyMeasurements?>> getMyMeasurements() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.measurements}/me',
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) return right(null);
      return right(BodyMeasurements.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Saves new measurements.
  Future<Either<AppException, BodyMeasurements>> saveMeasurements(
    BodyMeasurements measurements,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.measurements,
        data: measurements.toApi(),
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing measurements payload'));
      }
      return right(BodyMeasurements.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Creates a workshop/home visit booking.
  Future<Either<AppException, String>> createBooking({
    required String type,
    required String date,
    required String timeSlot,
    String? address,
    String? city,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.bookings,
        data: {
          'type': type,
          'date': date,
          'timeSlot': timeSlot,
          'address': address,
          'city': city,
        },
        options: await _authOptions(),
      );
      final reference = response.data?['reference']?.toString();
      if (reference == null || reference.isEmpty) {
        return left(const ServerException(500, 'Missing booking reference'));
      }
      return right(reference);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Requests AI-estimated measurements from uploaded image bytes.
  Future<Either<AppException, BodyMeasurements>> estimateFromImageBase64(
    String imageBase64,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.ai}/measure',
        data: {'imageBase64': imageBase64},
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing AI measurement payload'));
      }
      return right(BodyMeasurements.fromApi(data));
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
