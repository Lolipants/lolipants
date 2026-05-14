import 'dart:convert';

/// Known role values recognised by role-based routing. The canonical set is
/// validated server-side; unknown values fall back to treating the account
/// like a regular user.
abstract final class UserRoles {
  /// Regular customer account.
  static const String user = 'user';

  /// Fulfilment partner that claims orders and advances tailoring status.
  static const String tailor = 'tailor';

  /// Delivery-person account that moves fulfilled orders to customers.
  static const String delivery = 'delivery';

  /// Admin account with scope-gated access to the admin shell.
  static const String admin = 'admin';

  /// All roles currently supported by the app.
  static const Set<String> all = {user, tailor, delivery, admin};
}

/// Canonical admin scope strings. Presence of `*` means super admin.
abstract final class AdminScopes {
  /// Super admin sentinel - grants every scope.
  static const String superAdmin = '*';

  /// Promote/demote users, manage bans.
  static const String usersMgmt = 'users_mgmt';

  /// View/force-status-change/reassign any order.
  static const String ordersOversight = 'orders_oversight';

  /// Approve + mark commission payouts as paid.
  static const String payouts = 'payouts';

  /// Hide posts/showcase items, void commissions.
  static const String moderation = 'moderation';

  /// Manage mannequins / fabrics / patterns / presets (admin CMS).
  static const String cms = 'cms';

  /// View and resolve user-submitted complaints.
  static const String complaints = 'complaints';

  /// Sub-scope: manage tailor accounts only.
  static const String tailorMgmt = 'tailor_mgmt';

  /// Sub-scope: manage delivery accounts only.
  static const String deliveryMgmt = 'delivery_mgmt';
}

/// Signed-in user snapshot cached locally and returned from Better Auth.
class User {
  /// Creates a user value.
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.adminScopes = const <String>[],
    this.imageUrl,
  });

  /// Parses [json] from Better Auth or local cache.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString(),
      adminScopes: _parseScopes(json['adminScopes'] ?? json['admin_scopes']),
      imageUrl: json['image']?.toString() ?? json['imageUrl']?.toString(),
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

  /// Scopes granted to an admin account. Empty for non-admin users. Contains
  /// [AdminScopes.superAdmin] for super admins.
  final List<String> adminScopes;

  /// Profile image URL from Better Auth (`image` field).
  final String? imageUrl;

  /// Normalised lowercase role. Defaults to [UserRoles.user] when absent or
  /// when the server sends an unknown value (avoids bad routing in [homeForRole]).
  String get normalizedRole {
    final raw = role?.trim().toLowerCase() ?? '';
    if (raw.isEmpty) return UserRoles.user;
    if (!UserRoles.all.contains(raw)) {
      return UserRoles.user;
    }
    return raw;
  }

  /// True when the account is an admin.
  bool get isAdmin => normalizedRole == UserRoles.admin;

  /// True when the admin has the `*` super-admin sentinel.
  bool get isSuperAdmin => isAdmin && adminScopes.contains(AdminScopes.superAdmin);

  /// True when a regular admin has the given [scope] (or is super admin).
  ///
  /// Matches [lolipants-api] [requireAdmin]: empty [adminScopes] means full
  /// dashboard access until scopes are assigned explicitly.
  bool hasScope(String scope) {
    if (!isAdmin) return false;
    if (adminScopes.isEmpty) return true;
    if (adminScopes.contains(AdminScopes.superAdmin)) return true;
    return adminScopes.contains(scope);
  }

  /// Merges role and admin scopes from [lolipants-api] `GET /users/me` (D1 is
  /// authoritative; Better Auth can lag after promotion).
  User copyWithAppMe(Map<String, dynamic> me) {
    var newRole = role;
    if (me.containsKey('role')) {
      final r = me['role'];
      if (r == null) {
        newRole = null;
      } else {
        final s = r.toString();
        newRole = s.isEmpty ? null : s;
      }
    }
    var newScopes = adminScopes;
    if (me.containsKey('adminScopes') || me.containsKey('admin_scopes')) {
      newScopes = _parseScopes(me['adminScopes'] ?? me['admin_scopes']);
    }
    return User(
      id: id,
      name: name,
      email: email,
      role: newRole,
      adminScopes: newScopes,
      imageUrl: imageUrl,
    );
  }

  /// JSON suitable for secure storage.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (role != null) 'role': role,
        if (adminScopes.isNotEmpty) 'adminScopes': adminScopes,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'image': imageUrl,
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

List<String> _parseScopes(Object? raw) {
  if (raw == null) return const <String>[];
  if (raw is List) {
    return raw
        .map((v) => v?.toString().trim() ?? '')
        .where((v) => v.isNotEmpty)
        .toList(growable: false);
  }
  var text = raw.toString().trim();
  if (text.isEmpty) return const <String>[];
  if (text.startsWith('"') && text.endsWith('"')) {
    try {
      final unwrapped = jsonDecode(text);
      if (unwrapped is String) {
        text = unwrapped.trim();
      }
    } on FormatException {
      // keep text
    }
  }
  if (text.startsWith('[')) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded
            .map((v) => v?.toString().trim() ?? '')
            .where((v) => v.isNotEmpty)
            .toList(growable: false);
      }
      if (decoded is String && decoded.trim().startsWith('[')) {
        final inner = jsonDecode(decoded);
        if (inner is List) {
          return inner
              .map((v) => v?.toString().trim() ?? '')
              .where((v) => v.isNotEmpty)
              .toList(growable: false);
        }
      }
    } on FormatException {
      // fall through
    }
  }
  return text
      .split(',')
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toList(growable: false);
}
