import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  /// Deletes the current user on better-auth and clears local credentials.
  Future<Either<AppException, void>> deleteAccount() async {
    try {
      await _dio.post<void>(ApiEndpoints.authDeleteAccount, data: const {});
    } on DioException catch (e) {
      if ((e.response?.statusCode ?? 0) >= 500) {
        return left(_mapDio(e));
      }
    } on Exception {
      // Swallow transport errors; session is cleared below regardless.
    }
    await _storage.clearAll();
    return right(null);
  }

  /// Patches the current user's display name (and optional avatar URL) via
  /// better-auth. The `/update-user` endpoint returns `{ status: true }` only,
  /// so we refresh the session to obtain the updated user.
  Future<Either<AppException, User>> updateProfile({
    required String name,
    String? image,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authUpdateUser,
        data: {
          'name': name,
          if (image != null && image.trim().isNotEmpty) 'image': image.trim(),
        },
      );
      final sessionResult = await getSession();
      return sessionResult.fold(
        left,
        (user) =>
            user != null ? right(user) : left(const UnknownException()),
      );
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Ends the session on the server and clears local credentials.
  Future<Either<AppException, void>> signOut() async {
    try {
      if ((dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim() ?? '').isNotEmpty) {
        await GoogleSignIn.instance.signOut();
      }
    } on Exception {
      // Ignore; native Google session may be absent.
    }
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

  /// Loads the current user, preferring a live [ApiEndpoints.authGetSession] call
  /// so [User.role] matches the server (e.g. after promotion). Uses cached user
  /// only when the token exists and the request fails with a transport-style error.
  Future<Either<AppException, User?>> getSession() async {
    final token = await _storage.readSessionToken();
    if (token == null || token.isEmpty) {
      return right(null);
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.authGetSession,
      );
      final user = _parseUser(response.data);
      if (user != null) {
        final merged = await _tryMergeAppProfile(user);
        await _storage.writeUserJson(merged.toJsonString());
        return right(merged);
      }
      await _storage.clearAll();
      return right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.clearAll();
        return left(_mapDio(e));
      }
      if (_dioErrorAllowsStaleCache(e)) {
        final cached = await _storage.readUserJson();
        if (cached != null && cached.isNotEmpty) {
          try {
            final map = jsonDecode(cached) as Map<String, dynamic>;
            return right(User.fromJson(map));
          } on Exception {
            await _storage.clearAll();
            return left(_mapDio(e));
          }
        }
      }
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  static bool _dioErrorAllowsStaleCache(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  /// [lolipants-api] D1 row wins over Better Auth for RBAC. Call after session parse.
  Future<User> _tryMergeAppProfile(User authUser) async {
    final base = dotenv.env['API_BASE_URL']?.trim() ?? '';
    if (base.isEmpty) {
      return authUser;
    }
    final token = await _storage.readSessionToken();
    if (token == null || token.isEmpty) {
      return authUser;
    }
    try {
      final d = Dio(
        BaseOptions(
          baseUrl: base,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      final res = await d.get<Map<String, dynamic>>('${ApiEndpoints.users}/me');
      final data = res.data;
      if (data == null) {
        return authUser;
      }
      return authUser.copyWithAppMe(data);
    } on DioException {
      return authUser;
    } on Exception {
      return authUser;
    }
  }

  /// Native Google Sign-In, then Better Auth `signIn.social` with an ID token
  /// (see https://better-auth.com/docs/authentication/google).
  Future<Either<AppException, User>> signInWithGoogle() async {
    final serverId = dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim() ?? '';
    if (serverId.isEmpty) {
      return left(const AuthException('missing_google_server_client_id'));
    }
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile', 'openid'],
      );
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        await GoogleSignIn.instance.signOut();
        return left(const AuthException('missing_google_id_token'));
      }
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authSignInSocial,
        data: {
          'provider': 'google',
          'idToken': {
            'token': idToken,
          },
        },
      );
      await GoogleSignIn.instance.signOut();
      return _persistSessionFromResponse(response.data);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return left(const AuthException('google_sign_in_canceled'));
      }
      return left(const AuthException('google_sign_in_failed'));
    } on DioException catch (e) {
      try {
        await GoogleSignIn.instance.signOut();
      } on Exception {
        // ignore
      }
      return left(_mapDio(e));
    } on Exception {
      try {
        await GoogleSignIn.instance.signOut();
      } on Exception {
        // ignore
      }
      return left(const UnknownException());
    }
  }

  /// Native Sign in with Apple, then Better Auth `signIn.social` with an ID token.
  Future<Either<AppException, User>> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        return left(const AuthException('missing_apple_id_token'));
      }
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authSignInSocial,
        data: {
          'provider': 'apple',
          'idToken': {
            'token': idToken,
            if (credential.authorizationCode.isNotEmpty)
              'accessToken': credential.authorizationCode,
          },
        },
      );
      final result = await _persistSessionFromResponse(response.data);
      return result.fold(
        left,
        (user) async {
          final given = credential.givenName?.trim();
          final family = credential.familyName?.trim();
          final parts = [given, family]
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .toList();
          if (parts.isNotEmpty && user.name.trim().isEmpty) {
            final patched = await updateProfile(name: parts.join(' '));
            return patched.fold((_) => right(user), right);
          }
          return right(user);
        },
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return left(const AuthException('apple_sign_in_canceled'));
      }
      return left(const AuthException('apple_sign_in_failed'));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Asks better-auth to email a 6-digit OTP to [email].
  Future<Either<AppException, Unit>> sendEmailOtp(String email) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authSendOtp,
        data: {'email': email, 'type': 'sign-in'},
      );
      return right(unit);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Exchanges an emailed OTP for a session.
  Future<Either<AppException, User>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authSignInOtp,
        data: {'email': email, 'otp': otp},
      );
      return _persistSessionFromResponse(response.data);
    } on DioException catch (e) {
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
      final merged = await _tryMergeAppProfile(user);
      await _storage.writeUserJson(merged.toJsonString());
      return right(merged);
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

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('timeout');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException('unreachable');
    }
    if (e.type == DioExceptionType.cancel) {
      return const UnknownException();
    }

    final parsed = _parseApiErrorMessage(body);

    if (status >= 500) {
      return ServerException(status, parsed ?? '');
    }
    if (status == 401 || status == 403) {
      return AuthException(
        parsed ?? (status == 401 ? 'invalid_credentials' : 'forbidden'),
      );
    }
    if (status >= 400) {
      return AuthException(parsed ?? 'request_failed');
    }
    if (status == 0) {
      return const NetworkException('unreachable');
    }

    final raw = e.message ?? '';
    if (_looksLikeRawDioError(raw)) {
      return const NetworkException('unreachable');
    }
    return NetworkException(raw.isEmpty ? 'unreachable' : raw);
  }

  /// Short, safe message from JSON body (never Dio's internal error text).
  String? _parseApiErrorMessage(dynamic body) {
    if (body is! Map) {
      return null;
    }
    final dynamic m = body['message'] ?? body['error'];
    if (m is! String || m.isEmpty) {
      return null;
    }
    if (m.length > 200) {
      return null;
    }
    if (_looksLikeRawDioError(m)) {
      return null;
    }
    return m;
  }

  bool _looksLikeRawDioError(String s) {
    final lower = s.toLowerCase();
    return lower.contains('dioexception') ||
        lower.contains('validatestatus') ||
        lower.contains('status code of') ||
        lower.contains('requestoptions') ||
        lower.contains('xmlhttprequest');
  }
}
