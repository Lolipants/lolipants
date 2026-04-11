/// Result envelope for Better Auth responses (expanded in Phase 2).
class AuthResult {
  const AuthResult._(this.message);

  /// Creates a successful auth placeholder.
  const AuthResult.success() : this._(null);

  /// Creates a failed auth placeholder.
  const AuthResult.failure(String message) : this._(message);

  /// Human-readable failure detail.
  final String? message;

  /// Whether the call succeeded.
  bool get isSuccess => message == null;
}

/// Better Auth REST client.
///
/// HTTP calls are implemented in Phase 2; methods currently throw.
class AuthRepository {
  /// Creates the repository (Dio wiring added in Phase 2).
  const AuthRepository();

  /// Registers a new user with email and password.
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    throw UnimplementedError('AuthRepository.signUp — Phase 2');
  }

  /// Signs in with email and password.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) {
    throw UnimplementedError('AuthRepository.signIn — Phase 2');
  }

  /// Ends the current session on the server.
  Future<void> signOut() {
    throw UnimplementedError('AuthRepository.signOut — Phase 2');
  }

  /// Fetches the active session, if any.
  Future<Object?> getSession() {
    throw UnimplementedError('AuthRepository.getSession — Phase 2');
  }

  /// Triggers a password reset email.
  Future<void> forgotPassword(String email) {
    throw UnimplementedError('AuthRepository.forgotPassword — Phase 2');
  }
}
