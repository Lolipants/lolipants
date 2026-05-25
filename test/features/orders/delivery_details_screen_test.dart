import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/orders/models/checkout_draft.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/features/orders/screens/delivery_details_screen.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

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
              deliveryLat: 25.2854,
              deliveryLng: 51.531,
            ),
          ),
        ],
        child: const MaterialApp(home: DeliveryDetailsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(LolipantsButton, 'Get price & tailor'),
    );
    await tester.tap(find.widgetWithText(LolipantsButton, 'Get price & tailor'));
    await tester.pump();

    expect(find.text('Required'), findsWidgets);
  });
}
