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
  // Dio throws with a long essay (validateStatus / MDN link) for many status
  // codes, especially 404 — never show that raw text in the UI.
  if (_isDioStatusBoilerplate(msg)) {
    if (code == 404) {
      return 'Not found (404). If you are using the app, make sure API_BASE_URL '
          'is your lolipants-api worker URL, not the Better Auth worker. Then '
          'restart the app.';
    }
    if (code >= 500) {
      return 'The server had a problem. Please try again in a moment.';
    }
    return fallback;
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
