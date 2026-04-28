import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/features/admin/shell/admin_shell.dart';
import 'package:lolipants/features/auth/models/user.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';

class _AuthStub extends AuthNotifier {
  _AuthStub(this._user);
  final User _user;

  @override
  Future<AuthState> build() async => AuthAuthenticated(_user);
}

GoRouter _makeAdminRouter() {
  return GoRouter(
    initialLocation: '/admin/stats',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin/stats', builder: (c, s) => const _Page('stats')),
          GoRoute(path: '/admin/users', builder: (c, s) => const _Page('users')),
          GoRoute(path: '/admin/orders', builder: (c, s) => const _Page('orders')),
          GoRoute(path: '/admin/payouts', builder: (c, s) => const _Page('payouts')),
          GoRoute(path: '/admin/moderation', builder: (c, s) => const _Page('moderation')),
          GoRoute(path: '/admin/cms', builder: (c, s) => const _Page('cms')),
          GoRoute(path: '/admin/complaints', builder: (c, s) => const _Page('complaints')),
        ],
      ),
    ],
  );
}

class _Page extends StatelessWidget {
  const _Page(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Center(child: Text('page-$label'));
}

void main() {
  testWidgets('super admin sees every dashboard tab', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _AuthStub(
              const User(
                id: 'a-0',
                name: 'Super',
                email: 's@x',
                role: 'admin',
                adminScopes: ['*'],
              ),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: _makeAdminRouter()),
      ),
    );
    await tester.pump();

    for (final label in [
      'Stats',
      'Users',
      'Orders',
      'Payouts',
      'Moderation',
      'CMS',
      'Complaints',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '$label tab visible');
    }
  });

  testWidgets('scoped admin only sees allowed tabs + the always-visible stats',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _AuthStub(
              const User(
                id: 'a-1',
                name: 'Scoped',
                email: 'sc@x',
                role: 'admin',
                adminScopes: ['users_mgmt', 'payouts'],
              ),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: _makeAdminRouter()),
      ),
    );
    await tester.pump();

    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Payouts'), findsOneWidget);
    expect(find.text('Orders'), findsNothing);
    expect(find.text('Moderation'), findsNothing);
    expect(find.text('Complaints'), findsNothing);
    expect(find.text('CMS'), findsNothing);
  });
}
