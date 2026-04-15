import 'dart:convert';

/// Signed-in user snapshot cached locally and returned from Better Auth.
class User {
  /// Creates a user value.
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
  });

  /// Parses [json] from Better Auth or local cache.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString(),
    );
  }

  /// Stable user id from the auth server.
  final String id;

  /// Display name.
  final String name;

  /// Primary email.
  final String email;

  /// Optional role string from the server.
  final String? role;

  /// JSON suitable for secure storage.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (role != null) 'role': role,
      };

  /// Encodes this user as a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Uppercase initials for avatar chips (up to two letters).
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final s = parts.single;
      return s.isEmpty ? '?' : s.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
