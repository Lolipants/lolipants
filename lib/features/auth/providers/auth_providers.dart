import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/core/push/onesignal_bootstrap.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/auth/data/auth_repository.dart';
import 'package:lolipants/features/auth/models/user.dart';
import 'package:lolipants/features/settings/data/push_repository.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

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
  /// Prevents overlapping native social sign-in attempts.
  bool _socialSignInInFlight = false;

  /// True while [_afterAuthenticated] is running (post-login init window).
  /// The 401 interceptor must not treat failures during this window as
  /// session expiry — e.g. [GET /users/me] returning 401 for a brand-new
  /// account that has no profile row yet.
  bool _postAuthInit = false;

  /// Whether the notifier is currently inside the post-auth init window.
  bool get isPostAuthInit => _postAuthInit;

  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.getSession();
    final authState = result.fold(
      (_) => const AuthUnauthenticated(),
      (user) =>
          user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
    );
    if (authState is AuthAuthenticated) {
      await _afterAuthenticated(authState.user);
    }
    return authState;
  }

  Future<void> _afterAuthenticated(User user) async {
    _postAuthInit = true;
    try {
      await linkOneSignalUser(user.id);
      await ref.read(userGenderProvider.notifier).syncFromApi();
      if (ref.read(settingsProvider).pushEnabled) {
        final playerId = await currentPlayerId();
        if (playerId != null && playerId.isNotEmpty) {
          await ref.read(pushRepositoryProvider).registerPlayerId(playerId);
        }
      }
    } finally {
      _postAuthInit = false;
    }
  }

  Future<void> _afterSignedOut() async {
    await unlinkOneSignalUser();
    await ref.read(userGenderProvider.notifier).clear();
  }

  /// Re-runs the initial session restore (e.g. after token changes).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.getSession();
      final authState = result.fold(
        (_) => const AuthUnauthenticated(),
        (user) => user != null
            ? AuthAuthenticated(user)
            : const AuthUnauthenticated(),
      );
      if (authState is AuthAuthenticated) {
        await _afterAuthenticated(authState.user);
      }
      return authState;
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
    if (result case Right(value: final user)) {
      await _afterAuthenticated(user);
    }
    return result;
  }

  /// Signs up and updates [authProvider] on success.
  ///
  /// [gender] is persisted to both local storage and the API before the router
  /// redirect fires, so it is reliably tied to the account even if the signup
  /// screen dismounts immediately after this method returns.
  ///
  /// [avatarUrl] (an already-uploaded URL) is patched onto the Better Auth
  /// profile before the state transition so it is also saved atomically.
  ///
  /// [_afterAuthenticated] runs *before* [AuthAuthenticated] is announced so
  /// the signup screen stays mounted long enough for any remaining UI work.
  Future<Either<AppException, User>> signUpWithProfile({
    required String name,
    required String email,
    required String password,
    String? avatarUrl,
    String? gender,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signUp(
      name: name,
      email: email,
      password: password,
    );
    return result.fold(
      left,
      (user) async {
        User current = user;
        await _afterAuthenticated(current);
        // Persist gender before announcing authenticated state so that a 401
        // from the API (new user — profile row being created) cannot trigger
        // session-expiry and gender is always tied to the account.
        if (gender != null && gender.trim().isNotEmpty) {
          await ref
              .read(userGenderProvider.notifier)
              .persistGender(gender.trim());
        }
        if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
          final patched = await repo.updateProfile(
            name: name.trim(),
            image: avatarUrl.trim(),
          );
          patched.fold((_) {}, (u) => current = u);
        }
        state = AsyncValue.data(AuthAuthenticated(current));
        ref.read(authRecoveryMessageProvider.notifier).state = null;
        return right(current);
      },
    );
  }

  /// Starts Google OAuth against better-auth and updates [authProvider] on
  /// success.
  Future<Either<AppException, User>> signInWithGoogle() async {
    if (_socialSignInInFlight) {
      return left(const AuthException('oauth_in_progress'));
    }
    _socialSignInInFlight = true;
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
      if (result case Right(value: final user)) {
        await _afterAuthenticated(user);
      }
      return result;
    } finally {
      _socialSignInInFlight = false;
    }
  }

  /// Native Sign in with Apple via better-auth ID token exchange.
  Future<Either<AppException, User>> signInWithApple() async {
    if (_socialSignInInFlight) {
      return left(const AuthException('oauth_in_progress'));
    }
    _socialSignInInFlight = true;
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithApple();
      result.fold(
        (_) {},
        (user) {
          state = AsyncValue.data(AuthAuthenticated(user));
          ref.read(authRecoveryMessageProvider.notifier).state = null;
        },
      );
      if (result case Right(value: final user)) {
        await _afterAuthenticated(user);
      }
      return result;
    } finally {
      _socialSignInInFlight = false;
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
    if (result case Right(value: final user)) {
      await _afterAuthenticated(user);
    }
    return result;
  }

  /// Clears the server session and local credentials, then updates state.
  Future<Either<AppException, void>> signOutEverywhere() async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signOut();
    await _afterSignedOut();
    state = const AsyncValue.data(AuthUnauthenticated());
    return result;
  }

  /// Deletes the authenticated user on better-auth and resets local state.
  Future<Either<AppException, void>> deleteAccount() async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.deleteAccount();
    await _afterSignedOut();
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
    await unlinkOneSignalUser();
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
