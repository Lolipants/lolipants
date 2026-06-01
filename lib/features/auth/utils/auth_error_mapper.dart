import 'dart:ui' show Locale;

import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/errors/app_exception.dart';

/// Maps [AppException] values to short user-facing copy.
///
/// When [locale] is Arabic, returns the matching `*Ar` string where available.
String mapAuthExceptionToUserMessage(AppException e, {Locale? locale}) {
  return switch (e) {
    AuthException(:final message) => _mapAuthMessage(message, locale),
    NetworkException(:final message) => _mapNetworkMessage(message, locale),
    ServerException(:final statusCode, :final message) =>
      _mapServerMessage(statusCode, message, locale),
    UnknownException() => _l(locale, AppStrings.errorAuthGeneric),
  };
}

String _l(Locale? locale, String en, [String? ar]) {
  if (locale?.languageCode == 'ar' && ar != null) return ar;
  return en;
}

String _mapAuthMessage(String message, Locale? locale) {
  if (_looksLikeRawClientError(message)) {
    return _l(locale, AppStrings.errorAuthGeneric, AppStrings.errorAuthGenericAr);
  }
  final trimmed = message.trim();
  if (trimmed.isEmpty || trimmed.length > 200) {
    return _l(locale, AppStrings.errorAuthGeneric, AppStrings.errorAuthGenericAr);
  }
  return switch (trimmed) {
    'invalid_credentials' => _l(
      locale,
      AppStrings.errorInvalidCredentials,
      AppStrings.errorInvalidCredentialsAr,
    ),
    'forbidden' => _l(
      locale,
      AppStrings.errorForbidden,
      AppStrings.errorForbiddenAr,
    ),
    'request_failed' => _l(
      locale,
      AppStrings.errorAuthGeneric,
      AppStrings.errorAuthGenericAr,
    ),
    'network' => _l(
      locale,
      AppStrings.errorNetworkUnreachable,
      AppStrings.errorNetworkUnreachableAr,
    ),
    'invalid_response' => _l(
      locale,
      AppStrings.errorAuthGeneric,
      AppStrings.errorAuthGenericAr,
    ),
    'missing_authorize_url' => _l(
      locale,
      AppStrings.errorAuthGeneric,
      AppStrings.errorAuthGenericAr,
    ),
    'missing_session_token' => _l(
      locale,
      AppStrings.errorAuthGeneric,
      AppStrings.errorAuthGenericAr,
    ),
    'missing_google_server_client_id' => _l(
      locale,
      AppStrings.errorGoogleServerClientIdMissing,
      AppStrings.errorGoogleServerClientIdMissingAr,
    ),
    'missing_google_id_token' => _l(
      locale,
      AppStrings.errorAuthGeneric,
      AppStrings.errorAuthGenericAr,
    ),
    'google_sign_in_canceled' => _l(
      locale,
      'Sign in was canceled.',
      'تم إلغاء تسجيل الدخول.',
    ),
    'google_sign_in_failed' => _l(
      locale,
      AppStrings.errorAuthGeneric,
      AppStrings.errorAuthGenericAr,
    ),
    'apple_sign_in_canceled' => _l(
      locale,
      'Sign in was canceled.',
      'تم إلغاء تسجيل الدخول.',
    ),
    'apple_sign_in_failed' => _l(
      locale,
      AppStrings.errorAuthGeneric,
      AppStrings.errorAuthGenericAr,
    ),
    'missing_apple_id_token' => _l(
      locale,
      AppStrings.errorAuthGeneric,
      AppStrings.errorAuthGenericAr,
    ),
    'invalid_session' => _l(
      locale,
      AppStrings.errorAuthGeneric,
      AppStrings.errorAuthGenericAr,
    ),
    _ => trimmed,
  };
}

String _mapNetworkMessage(String message, Locale? locale) {
  return switch (message) {
    'timeout' => _l(
      locale,
      AppStrings.errorNetworkTimeout,
      AppStrings.errorNetworkTimeoutAr,
    ),
    'unreachable' => _l(
      locale,
      AppStrings.errorNetworkUnreachable,
      AppStrings.errorNetworkUnreachableAr,
    ),
    final m
        when m.length <= 200 && !_looksLikeRawClientError(m) =>
      m,
    _ => _l(
      locale,
      AppStrings.errorNetworkUnreachable,
      AppStrings.errorNetworkUnreachableAr,
    ),
  };
}

String _mapServerMessage(int code, String message, Locale? locale) {
  if (message.isNotEmpty && !_looksLikeRawClientError(message)) {
    return message;
  }
  return switch (code) {
    502 => _l(
      locale,
      AppStrings.errorHttpBadGateway,
      AppStrings.errorHttpBadGatewayAr,
    ),
    503 => _l(
      locale,
      AppStrings.errorHttpServiceUnavailable,
      AppStrings.errorHttpServiceUnavailableAr,
    ),
    504 => _l(
      locale,
      AppStrings.errorHttpGatewayTimeout,
      AppStrings.errorHttpGatewayTimeoutAr,
    ),
    final c when c >= 500 && c < 600 => _l(
      locale,
      AppStrings.errorHttpServerError,
      AppStrings.errorHttpServerErrorAr,
    ),
    _ => _l(
      locale,
      AppStrings.errorHttpServerError,
      AppStrings.errorHttpServerErrorAr,
    ),
  };
}

bool _looksLikeRawClientError(String s) {
  final lower = s.toLowerCase();
  return lower.contains('dioexception') ||
      lower.contains('validatestatus') ||
      lower.contains('status code of') ||
      lower.contains('requestoptions') ||
      lower.contains('xmlhttprequest');
}
