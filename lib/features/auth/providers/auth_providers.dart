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

/// Pending post-login route captured when session expires.
final pendingAuthReturnToProvider = StateProvider<String?>((ref) => null);

/// Optional user-facing session recovery message.
final authRecoveryMessageProvider = StateProvider<String?>((ref) => null);

/// Riverpod notifier coordinating session restore and sign-in/out.
class AuthNotifier extends AsyncNotifier<AuthState> {
  /// Prevents overlapping Google OAuth; a second call would replace the
  /// native plugin callback and open another browser session.
  bool _googleOAuthInFlight = false;

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
      (user) {
        state = AsyncValue.data(AuthAuthenticated(user));
        ref.read(authRecoveryMessageProvider.notifier).state = null;
      },
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
      (user) {
        state = AsyncValue.data(AuthAuthenticated(user));
        ref.read(authRecoveryMessageProvider.notifier).state = null;
      },
    );
    return result;
  }

  /// Starts Google OAuth against better-auth and updates [authProvider] on
  /// success.
  Future<Either<AppException, User>> signInWithGoogle() async {
    if (_googleOAuthInFlight) {
      return left(const AuthException('oauth_in_progress'));
    }
    _googleOAuthInFlight = true;
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithGoogle();
      result.fold(
        (_) {},
        (user) {
          state = AsyncValue.data(AuthAuthenticated(user));
          ref.read(authRecoveryMessageProvider.notifier).state = null;
        },
      );
      return result;
    } finally {
      _googleOAuthInFlight = false;
    }
  }

  /// Asks better-auth to email a 6-digit OTP to [email].
  Future<Either<AppException, Unit>> sendEmailOtp(String email) async {
    final repo = ref.read(authRepositoryProvider);
    return repo.sendEmailOtp(email);
  }

  /// Verifies an emailed OTP and updates [authProvider] on success.
  Future<Either<AppException, User>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.verifyEmailOtp(email: email, otp: otp);
    result.fold(
      (_) {},
      (user) {
        state = AsyncValue.data(AuthAuthenticated(user));
        ref.read(authRecoveryMessageProvider.notifier).state = null;
      },
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

  /// Deletes the authenticated user on better-auth and resets local state.
  Future<Either<AppException, void>> deleteAccount() async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.deleteAccount();
    state = const AsyncValue.data(AuthUnauthenticated());
    return result;
  }

  /// Updates the current user's display name and refreshes local state.
  Future<Either<AppException, User>> updateProfile({
    required String name,
    String? image,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.updateProfile(name: name, image: image);
    result.fold(
      (_) {},
      (user) => state = AsyncValue.data(AuthAuthenticated(user)),
    );
    return result;
  }

  /// Forces local sign-out state (used by API interceptors on 401).
  Future<void> forceSignOutLocal() async {
    final storage = ref.read(authLocalStorageProvider);
    await storage.clearAll();
    state = const AsyncValue.data(AuthUnauthenticated());
  }

  /// Captures the desired destination and moves auth state to signed out.
  Future<void> handleUnauthorized({String? returnTo}) async {
    final normalized = returnTo?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      ref.read(pendingAuthReturnToProvider.notifier).state = normalized;
    }
    ref.read(authRecoveryMessageProvider.notifier).state =
        'Your session expired. Please sign in to continue.';
    await forceSignOutLocal();
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
