import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/orders/screens/order_confirmation_screen.dart';

void main() {
  testWidgets('confirmation screen shows order reference and CTAs',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OrderConfirmationScreen(orderId: 'ord_test_1234'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Order confirmed'), findsOneWidget);
    expect(find.textContaining('ord_test_1234'), findsOneWidget);
    expect(find.text('Track order'), findsOneWidget);
    expect(find.text('Continue designing'), findsOneWidget);
  });
}
