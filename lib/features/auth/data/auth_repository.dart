import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/auth/models/user.dart';

/// Better Auth REST client returning [Either] for all operations.
class AuthRepository {
  /// Creates a repository with a dedicated auth [Dio] and [storage].
  AuthRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Registers a new user and establishes a session when successful.
  Future<Either<AppException, User>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authSignUpEmail,
        data: {'name': name, 'email': email, 'password': password},
      );
      return _persistSessionFromResponse(response.data);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Signs in with email and password.
  Future<Either<AppException, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authSignInEmail,
        data: {'email': email, 'password': password},
      );
      return _persistSessionFromResponse(response.data);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Ends the session on the server and clears local credentials.
  Future<Either<AppException, void>> signOut() async {
    try {
      await _dio.post<void>(ApiEndpoints.authSignOut, data: const {});
    } on DioException catch (_) {
      // Server may already have invalidated the session.
    } on Exception {
      // Ignore transport errors; always clear locally.
    }
    await _storage.clearAll();
    return right(null);
  }

  /// Validates the stored token with the server when possible.
  Future<Either<AppException, User?>> getSession() async {
    final token = await _storage.readSessionToken();
    if (token == null || token.isEmpty) {
      return right(null);
    }
    final cached = await _storage.readUserJson();
    if (cached != null && cached.isNotEmpty) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        return right(User.fromJson(map));
      } on Exception {
        await _storage.clearAll();
        return right(null);
      }
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.authGetSession,
      );
      final user = _parseUser(response.data);
      if (user != null) {
        await _storage.writeUserJson(user.toJsonString());
        return right(user);
      }
      await _storage.clearAll();
      return right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.clearAll();
      }
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Requests a password reset email from Better Auth.
  Future<Either<AppException, void>> forgotPassword(String email) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.authForgetPassword,
        data: {'email': email},
      );
      return right(null);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, User>> _persistSessionFromResponse(
    Map<String, dynamic>? data,
  ) async {
    final token = _extractToken(data);
    final user = _parseUser(data);
    if (token == null || user == null) {
      return left(const AuthException('invalid_response'));
    }
    try {
      await _storage.writeSessionToken(token);
      await _storage.writeUserJson(user.toJsonString());
      return right(user);
    } on Exception {
      return left(const UnknownException());
    }
  }

  String? _extractToken(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final direct = data['token'];
    if (direct is String && direct.isNotEmpty) {
      return direct;
    }
    final session = data['session'];
    if (session is Map<String, dynamic>) {
      final t = session['token'] ?? session['sessionToken'];
      if (t is String && t.isNotEmpty) {
        return t;
      }
    }
    return null;
  }

  User? _parseUser(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      return User.fromJson(user);
    }
    if (data.containsKey('id') && data.containsKey('email')) {
      return User.fromJson(data);
    }
    return null;
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final body = e.response?.data;
    var message = e.message ?? 'network';
    if (body is Map && body['message'] != null) {
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
      return AuthException(message);
    }
    return NetworkException(message);
  }
}
