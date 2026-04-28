import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/orders/models/checkout_draft.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/orders/screens/delivery_details_screen.dart';

void main() {
  testWidgets('delivery form surfaces validation errors on empty submit',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkoutDraftProvider.overrideWith(
            (ref) => const CheckoutDraft(
              design: OrderDesignDraft(
                designId: 'design-1',
                name: 'Thobe',
                garmentType: 'thobe',
                primaryColour: '#fff',
              ),
              idempotencyKey: 'k_test',
              city: 'Doha',
            ),
          ),
        ],
        child: const MaterialApp(home: DeliveryDetailsScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Continue to payment'));
    await tester.pump();

    expect(find.text('Required'), findsWidgets);
  });
}
