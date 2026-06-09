import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/delivery_strings.dart';
import 'package:lolipants/core/constants/orders_strings.dart';
import 'package:lolipants/features/auth/models/user.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/delivery/shell/delivery_shell.dart';
import 'package:lolipants/features/orders/screens/order_confirmation_screen.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

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
  testWidgets('delivery shell shows Arabic nav when locale is ar',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_AuthStub.new),
          settingsLocaleProvider.overrideWith((ref) => const Locale('ar')),
        ],
        child: MaterialApp.router(routerConfig: _makeDeliveryRouter()),
      ),
    );
    await tester.pump();

    expect(find.text(DeliveryStrings.dashboardTitleAr), findsOneWidget);
    expect(find.text(DeliveryStrings.navQueueAr), findsOneWidget);
    expect(find.text(DeliveryStrings.navActiveAr), findsOneWidget);
    expect(find.text(DeliveryStrings.navHistoryAr), findsOneWidget);
  });

  testWidgets('order confirmation shows Arabic copy when locale is ar',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsLocaleProvider.overrideWith((ref) => const Locale('ar')),
        ],
        child: const MaterialApp(
          home: OrderConfirmationScreen(orderId: 'ord_test_1234'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(OrdersStrings.orderConfirmedAr), findsOneWidget);
    expect(find.text(OrdersStrings.trackOrderAr), findsOneWidget);
    expect(find.text(OrdersStrings.continueDesigningAr), findsOneWidget);
  });
}
