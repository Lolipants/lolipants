import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/errors/app_exception.dart';

/// Maps [AppException] values to short user-facing copy.
String mapAuthExceptionToUserMessage(AppException e) {
  return switch (e) {
    AuthException(:final message) => _mapAuthMessage(message),
    NetworkException(:final message) => _mapNetworkMessage(message),
    ServerException(:final statusCode, :final message) =>
      _mapServerMessage(statusCode, message),
    UnknownException() => AppStrings.errorAuthGeneric,
  };
}

String _mapAuthMessage(String message) {
  if (_looksLikeRawClientError(message)) {
    return AppStrings.errorAuthGeneric;
  }
  final trimmed = message.trim();
  if (trimmed.isEmpty || trimmed.length > 200) {
    return AppStrings.errorAuthGeneric;
  }
  return switch (trimmed) {
    'invalid_credentials' => AppStrings.errorInvalidCredentials,
    'forbidden' => AppStrings.errorForbidden,
    'request_failed' => AppStrings.errorAuthGeneric,
    'network' => AppStrings.errorNetworkUnreachable,
    'invalid_response' => AppStrings.errorAuthGeneric,
    'missing_authorize_url' => AppStrings.errorAuthGeneric,
    'missing_session_token' => AppStrings.errorAuthGeneric,
    'missing_google_server_client_id' =>
      AppStrings.errorGoogleServerClientIdMissing,
    'missing_google_id_token' => AppStrings.errorAuthGeneric,
    'google_sign_in_canceled' => 'Sign in was canceled.',
    'google_sign_in_failed' => AppStrings.errorAuthGeneric,
    'invalid_session' => AppStrings.errorAuthGeneric,
    _ => trimmed,
  };
}

String _mapNetworkMessage(String message) {
  return switch (message) {
    'timeout' => AppStrings.errorNetworkTimeout,
    'unreachable' => AppStrings.errorNetworkUnreachable,
    final m
        when m.length <= 200 && !_looksLikeRawClientError(m) =>
      m,
    _ => AppStrings.errorNetworkUnreachable,
  };
}

String _mapServerMessage(int code, String message) {
  if (message.isNotEmpty && !_looksLikeRawClientError(message)) {
    return message;
  }
  return switch (code) {
    502 => AppStrings.errorHttpBadGateway,
    503 => AppStrings.errorHttpServiceUnavailable,
    504 => AppStrings.errorHttpGatewayTimeout,
    final c when c >= 500 && c < 600 => AppStrings.errorHttpServerError,
    _ => AppStrings.errorHttpServerError,
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
