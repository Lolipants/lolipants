import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/screens/order_summary_screen.dart';
import 'package:lolipants/features/sizing/models/body_measurements.dart';
import 'package:lolipants/features/sizing/providers/sizing_providers.dart';

void main() {
  testWidgets('renders typed draft details when provided', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myMeasurementsProvider.overrideWith(_MeasurementsStub.new),
        ],
        child: const MaterialApp(
          home: OrderSummaryScreen(
            designDraft: OrderDesignDraft(
              name: 'Evening Thobe',
              garmentType: 'thobe',
              primaryColour: '#112233',
              fabricId: 'cotton',
              patternId: 'plain',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Evening Thobe'), findsOneWidget);
    expect(find.text('thobe'), findsOneWidget);
    expect(find.text('cotton'), findsOneWidget);
    expect(find.textContaining('Sizing status'), findsOneWidget);
    expect(find.textContaining('Continue to delivery'), findsOneWidget);
  });

  testWidgets('uses fallback labels when no draft is passed',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myMeasurementsProvider.overrideWith(_NoMeasurementsStub.new),
        ],
        child: const MaterialApp(home: OrderSummaryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Current design'), findsOneWidget);
    expect(
      find.textContaining('Measurements are missing'),
      findsOneWidget,
    );
    expect(find.textContaining('Add measurements'), findsOneWidget);
  });
}

class _MeasurementsStub extends MyMeasurementsNotifier {
  @override
  Future<BodyMeasurements?> build() async =>
      const BodyMeasurements(chest: 100, waist: 80, height: 180);
}

class _NoMeasurementsStub extends MyMeasurementsNotifier {
  @override
  Future<BodyMeasurements?> build() async => null;
}
