import 'package:flutter_riverpod/flutter_riverpod.dart';

/// High-level authentication status for routing (Phase 2).
sealed class AuthState {
  const AuthState();
}

/// No active session.
class AuthUnauthenticated extends AuthState {
  /// Creates an unauthenticated state.
  const AuthUnauthenticated();
}

/// Authenticated user (details added in Phase 2).
class AuthAuthenticated extends AuthState {
  /// Creates an authenticated state placeholder.
  const AuthAuthenticated();
}

/// Exposes the current [AuthState] to the widget tree.
final authProvider = Provider<AuthState>(
  (ref) => const AuthUnauthenticated(),
);
