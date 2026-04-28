import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/features/auth/models/user.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/tailor/screens/tailor_active_orders_screen.dart';
import 'package:lolipants/features/tailor/screens/tailor_completed_orders_screen.dart';
import 'package:lolipants/features/tailor/screens/tailor_incoming_orders_screen.dart';
import 'package:lolipants/features/tailor/shell/tailor_shell.dart';

class _TailorAuthStub extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      AuthAuthenticated(const User(id: 't-1', name: 'T', email: 't@x', role: 'tailor'));
}

GoRouter _makeTailorRouter() {
  return GoRouter(
    initialLocation: '/tailor/incoming',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TailorShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tailor/incoming',
                builder: (c, s) => const TailorIncomingOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tailor/active',
                builder: (c, s) => const TailorActiveOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tailor/completed',
                builder: (c, s) => const TailorCompletedOrdersScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('tailor shell renders the three-tab navigation bar',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(_TailorAuthStub.new)],
        child: MaterialApp.router(routerConfig: _makeTailorRouter()),
      ),
    );
    await tester.pump();

    expect(find.text('Incoming'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Tailor dashboard'), findsOneWidget);
  });
}
