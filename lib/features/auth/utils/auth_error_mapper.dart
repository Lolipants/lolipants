import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/errors/app_exception.dart';

/// Maps [AppException] values to short user-facing copy.
String mapAuthExceptionToUserMessage(AppException e) {
  return switch (e) {
    AuthException(:final message) => message,
    NetworkException(:final message) => message,
    ServerException(:final message) => message,
    UnknownException() => AppStrings.errorAuthGeneric,
  };
}
