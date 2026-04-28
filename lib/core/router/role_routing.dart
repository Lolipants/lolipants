import 'package:lolipants/features/auth/models/user.dart';

/// Route each authenticated role to its default landing location.
String homeForRole(User user) {
  switch (user.normalizedRole) {
    case UserRoles.tailor:
      return '/tailor/incoming';
    case UserRoles.delivery:
      return '/delivery/queue';
    case UserRoles.admin:
      return '/admin';
    case UserRoles.user:
    default:
      return '/home';
  }
}

/// Preferred route after sign-in when [returnTo] is not set (e.g. no deep link).
String postAuthLocation(User user, String? returnTo) =>
    returnTo ?? homeForRole(user);
