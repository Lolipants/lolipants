/// Form validation helpers for auth and profile flows.
///
/// Return values are opaque error keys for mapping to user-facing copy in UI.
class Validators {
  Validators._();

  /// Returns `null` when the trimmed string is a plausible email, otherwise
  /// an English error token for display mapping.
  static String? emailErrorKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'required';
    }
    final email = value.trim();
    final basic = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!basic.hasMatch(email)) {
      return 'invalid_email';
    }
    return null;
  }

  /// Returns `null` when password meets minimum policy.
  static String? passwordSignupErrorKey(String? value) {
    if (value == null || value.isEmpty) {
      return 'required';
    }
    if (value.length < 8) {
      return 'password_short';
    }
    if (!RegExp('[0-9]').hasMatch(value)) {
      return 'password_no_digit';
    }
    return null;
  }

  /// Returns `null` when the trimmed name has at least two characters.
  static String? nameErrorKey(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'name_short';
    }
    return null;
  }
}
