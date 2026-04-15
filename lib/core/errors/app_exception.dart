/// Base type for recoverable failures surfaced to the UI layer.
sealed class AppException {
  /// Const constructor for subclasses.
  const AppException();
}

/// Connectivity or transport failures.
class NetworkException extends AppException {
  /// Creates a network exception with a short [message].
  const NetworkException(this.message);

  /// Human-readable explanation.
  final String message;
}

/// Authentication and session failures.
class AuthException extends AppException {
  /// Creates an auth exception with an opaque [message] code.
  const AuthException(this.message);

  /// Machine-oriented code such as `invalid_credentials`.
  final String message;
}

/// HTTP error responses from the API.
class ServerException extends AppException {
  /// Creates a server exception with [statusCode] and [message].
  const ServerException(this.statusCode, this.message);

  /// HTTP status from the response.
  final int statusCode;

  /// Parsed or fallback error text.
  final String message;
}

/// Catch-all when the failure cannot be classified.
class UnknownException extends AppException {
  /// Creates an unknown exception.
  const UnknownException();
}
