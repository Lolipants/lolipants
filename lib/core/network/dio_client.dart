import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';

final Logger _dioLogger = Logger('lolipants.network');

/// Builds the shared [Dio] instance used across repositories.
class DioClient {
  DioClient._();

  /// Creates a [Dio] with timeouts, JSON headers, and interceptors.
  static Dio create({
    Future<String?> Function()? readSessionToken,
    Future<void> Function()? onUnauthorized,
  }) {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        readSessionToken: readSessionToken,
        onUnauthorized: onUnauthorized,
      ),
    );
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
class AuthInterceptor extends Interceptor {
  /// Creates an auth interceptor for token attach and 401 handling.
  AuthInterceptor({
    this.readSessionToken,
    this.onUnauthorized,
  });

  /// Token reader invoked before every request.
  final Future<String?> Function()? readSessionToken;

  /// Callback invoked once when a 401 response is received.
  final Future<void> Function()? onUnauthorized;
  bool _isHandlingUnauthorized = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await readSessionToken?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      if (!_isHandlingUnauthorized) {
        _isHandlingUnauthorized = true;
        try {
          await onUnauthorized?.call();
        } finally {
          _isHandlingUnauthorized = false;
        }
      }
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
