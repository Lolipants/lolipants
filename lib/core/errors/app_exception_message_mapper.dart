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
      statusMessages[code] ?? msg,
    UnknownException() => fallback,
  };
}
