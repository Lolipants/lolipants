import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure persistence for session token and cached user JSON.
class AuthLocalStorage {
  /// Creates storage with the default encrypted preferences backend.
  AuthLocalStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Persists the opaque session token.
  Future<void> writeSessionToken(String token) =>
      _storage.write(key: _sessionKey, value: token);

  /// Reads the session token when present.
  Future<String?> readSessionToken() => _storage.read(key: _sessionKey);

  /// Persists cached user JSON (id, name, email, role).
  Future<void> writeUserJson(String json) =>
      _storage.write(key: _userKey, value: json);

  /// Reads cached user JSON when present.
  Future<String?> readUserJson() => _storage.read(key: _userKey);

  /// Clears auth material from secure storage.
  Future<void> clearAll() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _userKey);
  }

  static const String _sessionKey = 'lolipants_session_token';
  static const String _userKey = 'lolipants_user';
}
