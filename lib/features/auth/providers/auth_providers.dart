import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/auth/data/auth_repository.dart';
import 'package:lolipants/features/auth/models/user.dart';

/// Secure storage for auth material.
final authLocalStorageProvider = Provider<AuthLocalStorage>(
  (ref) => AuthLocalStorage(),
);

/// HTTP client scoped to `BETTER_AUTH_BASE_URL` with bearer injection.
final authDioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.env['BETTER_AUTH_BASE_URL'] ?? '';
  final configuredOrigin = dotenv.env['BETTER_AUTH_ORIGIN']?.trim() ?? '';
  final authOrigin = configuredOrigin.isNotEmpty ? configuredOrigin : baseUrl;
  final storage = ref.watch(authLocalStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        if (authOrigin.isNotEmpty) 'Origin': authOrigin,
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (authOrigin.isNotEmpty) {
          options.headers['Origin'] = authOrigin;
        }
        final token = await storage.readSessionToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});

/// Better Auth repository.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    dio: ref.watch(authDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// High-level authentication state for routing and UI.
final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Riverpod notifier coordinating session restore and sign-in/out.
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.getSession();
    return result.fold(
      (_) => const AuthUnauthenticated(),
      (user) =>
          user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
    );
  }

  /// Re-runs the initial session restore (e.g. after token changes).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.getSession();
      return result.fold(
        (_) => const AuthUnauthenticated(),
        (user) => user != null
            ? AuthAuthenticated(user)
            : const AuthUnauthenticated(),
      );
    });
  }

  /// Signs in and updates [authProvider] on success.
  Future<Either<AppException, User>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signIn(email: email, password: password);
    result.fold(
      (_) {},
      (user) => state = AsyncValue.data(AuthAuthenticated(user)),
    );
    return result;
  }

  /// Signs up and updates [authProvider] on success.
  Future<Either<AppException, User>> signUpWithProfile({
    required String name,
    required String email,
    required String password,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signUp(
      name: name,
      email: email,
      password: password,
    );
    result.fold(
      (_) {},
      (user) => state = AsyncValue.data(AuthAuthenticated(user)),
    );
    return result;
  }

  /// Clears the server session and local credentials, then updates state.
  Future<Either<AppException, void>> signOutEverywhere() async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signOut();
    state = const AsyncValue.data(AuthUnauthenticated());
    return result;
  }
}

/// Session states used by [authProvider].
sealed class AuthState {
  /// Const constructor for subclasses.
  const AuthState();
}

/// No valid session.
class AuthUnauthenticated extends AuthState {
  /// Unauthenticated marker.
  const AuthUnauthenticated();
}

/// Authenticated with a loaded [user].
class AuthAuthenticated extends AuthState {
  /// Authenticated state with [user].
  const AuthAuthenticated(this.user);

  /// Current user.
  final User user;
}
