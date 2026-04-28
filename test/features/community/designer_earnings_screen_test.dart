import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/community/models/commission.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/community/screens/designer_earnings_screen.dart';

Commission _commission({
  required String id,
  required double amount,
  required CommissionStatus status,
  String designName = 'Midnight Thobe',
  String? payoutReference,
}) {
  return Commission(
    id: id,
    orderId: 'order-$id',
    designerId: 'designer-1',
    buyerId: 'buyer-1',
    amount: amount,
    percentage: 10,
    status: status,
    createdAt: DateTime(2026, 4, 10),
    designName: designName,
    deliveryCity: 'Doha',
    payoutReference: payoutReference,
  );
}

void main() {
  testWidgets('renders earnings summary buckets + commission tiles',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          designerEarningsProvider.overrideWith(
            (_) => Future.value(
              const DesignerEarnings(
                currency: 'QAR',
                pending: EarningsBucket(count: 1, total: 49),
                approved: EarningsBucket(count: 1, total: 49),
                paid: EarningsBucket(count: 2, total: 80),
                voided: EarningsBucket(count: 0, total: 0),
              ),
            ),
          ),
          myCommissionsProvider(null).overrideWith(
            (_) => Future.value([
              _commission(
                id: 'c1',
                amount: 49,
                status: CommissionStatus.pending,
              ),
              _commission(
                id: 'c2',
                amount: 80,
                status: CommissionStatus.paid,
                payoutReference: 'BANK-REF-9',
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: DesignerEarningsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Earnings'), findsOneWidget);
    // Lifetime label + one of the bucket labels.
    expect(find.text('Lifetime earnings'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Void'), findsOneWidget);
    // Status pills.
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('PAID'), findsOneWidget);
    // Commission list.
    expect(find.text('Midnight Thobe'), findsNWidgets(2));
    expect(find.textContaining('Payout ref: BANK-REF-9'), findsOneWidget);
  });

  testWidgets('shows empty state when no commissions exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          designerEarningsProvider.overrideWith(
            (_) => Future.value(
              const DesignerEarnings(
                currency: 'QAR',
                pending: EarningsBucket(count: 0, total: 0),
                approved: EarningsBucket(count: 0, total: 0),
                paid: EarningsBucket(count: 0, total: 0),
                voided: EarningsBucket(count: 0, total: 0),
              ),
            ),
          ),
          myCommissionsProvider(null)
              .overrideWith((_) => Future.value(const <Commission>[])),
        ],
        child: const MaterialApp(home: DesignerEarningsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.textContaining('Publish a design to the showcase'),
      findsOneWidget,
    );
  });
}
