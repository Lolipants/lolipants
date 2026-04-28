import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/features/auth/models/user.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/delivery/shell/delivery_shell.dart';

class _AuthStub extends AuthNotifier {
  @override
  Future<AuthState> build() async => AuthAuthenticated(
        const User(
          id: 'd-1',
          name: 'Del',
          email: 'd@x',
          role: 'delivery',
        ),
      );
}

GoRouter _makeDeliveryRouter() {
  return GoRouter(
    initialLocation: '/delivery/queue',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            DeliveryShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delivery/queue',
                builder: (c, s) => const _Placeholder('queue'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delivery/active',
                builder: (c, s) => const _Placeholder('active'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/delivery/history',
                builder: (c, s) => const _Placeholder('history'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Center(child: Text('screen-$label'));
}

void main() {
  testWidgets('delivery shell exposes queue/active/history tabs',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_AuthStub.new)],
        child: MaterialApp.router(routerConfig: _makeDeliveryRouter()),
      ),
    );
    await tester.pump();

    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Delivery dashboard'), findsOneWidget);
  });
}
