import 'package:lolipants/core/errors/app_exception.dart';

/// Centralized message mapping for [AppException]-based failures.
String mapAppExceptionMessage(
  AppException error, {
  required String fallback,
  required String networkMessage,
  required String authMessage,
  Map<int, String> statusMessages = const {},
}) {
  return switch (error) {
    NetworkException() => networkMessage,
    AuthException() => authMessage,
    ServerException(statusCode: final code, message: final msg) =>
      _mapServerException(code, msg, statusMessages, fallback: fallback),
    UnknownException() => fallback,
  };
}

String _mapServerException(
  int code,
  String msg,
  Map<int, String> statusMessages, {
  required String fallback,
}) {
  final fromMap = statusMessages[code];
  if (fromMap != null) return fromMap;
  if (code >= 500) {
    // [Dio] often puts a multi-line essay in [DioException.message] when
    // validateStatus throws on 5xx, before JSON body is parsed. Don't show
    // that to end users; keep short API error strings when we have them.
    if (_isDioStatusBoilerplate(msg)) {
      return 'The server had a problem. Please try again in a moment.';
    }
  }
  return msg;
}

bool _isDioStatusBoilerplate(String msg) {
  final m = msg.toLowerCase();
  if (m.contains('validatestatus') && m.contains('status code of')) {
    return true;
  }
  if (m.contains('read more about status codes at') &&
      m.contains('developer.mozilla.org')) {
    return true;
  }
  return false;
}
