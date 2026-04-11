import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';

final Logger _dioLogger = Logger('lolipants.network');

/// Builds the shared [Dio] instance used across repositories.
class DioClient {
  DioClient._();

  /// Creates a [Dio] with timeouts, JSON headers, and interceptors.
  static Dio create() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(AuthInterceptor());
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: _dioLogger.fine,
        ),
      );
    }
    dio.interceptors.add(ErrorInterceptor());

    return dio;
  }
}

/// Attaches the Better Auth session bearer token when present.
///
/// Phase 2 will read the token from secure storage.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Token wiring is implemented in Phase 2.
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Phase 2: clear token and redirect to /login.
    }
    handler.next(err);
  }
}

/// Maps HTTP failures to application-level handling.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Typed app exception mapping is added with repositories in Phase 2+.
    handler.next(err);
  }
}
