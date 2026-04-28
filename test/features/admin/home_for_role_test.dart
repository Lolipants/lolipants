import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/router/role_routing.dart';
import 'package:lolipants/features/auth/models/user.dart';

void main() {
  group('homeForRole', () {
    test('routes regular users to /home', () {
      expect(
        homeForRole(const User(id: 'u', name: 'u', email: 'u@x', role: 'user')),
        '/home',
      );
    });

    test('routes tailors to the tailor shell', () {
      expect(
        homeForRole(
          const User(id: 'u', name: 'u', email: 'u@x', role: 'tailor'),
        ),
        '/tailor/incoming',
      );
    });

    test('routes delivery accounts to the delivery queue', () {
      expect(
        homeForRole(
          const User(id: 'u', name: 'u', email: 'u@x', role: 'delivery'),
        ),
        '/delivery/queue',
      );
    });

    test('routes admins to /admin (which then branches by scope)', () {
      expect(
        homeForRole(
          const User(
            id: 'u',
            name: 'u',
            email: 'u@x',
            role: 'admin',
            adminScopes: ['*'],
          ),
        ),
        '/admin',
      );
    });

    test('falls back to /home for unknown roles', () {
      expect(
        homeForRole(
          const User(id: 'u', name: 'u', email: 'u@x', role: 'mystery'),
        ),
        '/home',
      );
    });
  });

  group('postAuthLocation', () {
    const user = User(id: 'u', name: 'u', email: 'u@x', role: 'admin');

    test('uses returnTo when set', () {
      expect(postAuthLocation(user, '/orders'), '/orders');
    });

    test('uses homeForRole when returnTo is null', () {
      expect(postAuthLocation(user, null), '/admin');
    });
  });
}
