/// Relative Better Auth and API paths (joined with base URLs from env).
abstract final class ApiEndpoints {
  /// Better Auth email sign-up.
  static const String authSignUpEmail = '/auth/sign-up/email';

  /// Better Auth email sign-in.
  static const String authSignInEmail = '/auth/sign-in/email';

  /// Better Auth sign-out.
  static const String authSignOut = '/auth/sign-out';

  /// Better Auth session lookup.
  static const String authGetSession = '/auth/get-session';

  /// Better Auth forgot password.
  static const String authForgetPassword = '/auth/forget-password';

  /// Better Auth reset password.
  static const String authResetPassword = '/auth/reset-password';
}
