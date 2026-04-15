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

  /// Better Auth password reset request.
  static const String authForgetPassword = '/auth/request-password-reset';

  /// Better Auth reset password.
  static const String authResetPassword = '/auth/reset-password';

  /// Orders collection path.
  static const String orders = '/orders';

  /// Measurements collection path.
  static const String measurements = '/measurements';

  /// Designs collection path.
  static const String designs = '/designs';

  /// Fabrics collection path.
  static const String fabrics = '/fabrics';

  /// Presets collection path.
  static const String presets = '/presets';

  /// Upload endpoint.
  static const String upload = '/upload';

  /// AI proxy root path.
  static const String ai = '/ai';
  static const String aiMannequin = '/ai/mannequin';

  /// Community root path.
  static const String community = '/community';

  /// Posts root path.
  static const String posts = '/posts';

  /// Bookings root path.
  static const String bookings = '/bookings';

  /// Users root path.
  static const String users = '/users';

  /// Admin-managed mannequin options.
  static const String mannequins = '/mannequins';
}
