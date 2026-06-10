import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/home/models/home_flow_selection.dart';
import 'package:lolipants/features/home/providers/home_flow_provider.dart';
import 'package:lolipants/features/home/widgets/home_design_flow.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';
import 'package:lolipants/features/wedding/models/wedding_flow_args.dart';
import 'package:lolipants/features/wedding/screens/wedding_dress_browse_screen.dart';
import 'package:lolipants/features/wedding/screens/wedding_dress_detail_screen.dart';
import 'package:lolipants/features/wedding/screens/wedding_fulfillment_screen.dart';

void main() {
  testWidgets('WeddingDressBrowseScreen shows category filters', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WeddingDressBrowseScreen(
            flowArgs: WeddingFlowArgs(fulfillment: WeddingFulfillment.rent),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Wedding'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Bridal'), findsOneWidget);
    expect(find.text('Bridesmaids'), findsOneWidget);
  });

  testWidgets('WeddingFulfillmentScreen shows Rent and Buy choices',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WeddingFulfillmentScreen(),
        ),
      ),
    );

    expect(
      find.text('How would you like to get your dress?'),
      findsOneWidget,
    );
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Buy'), findsOneWidget);
    expect(
      find.text('Rent for your event and return the dress after'),
      findsOneWidget,
    );
    expect(find.text('Purchase and keep the dress forever'), findsOneWidget);
  });

  testWidgets('Home wedding service step shows Rent and Buy not Design yourself',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeFlowSelectionProvider.overrideWith(
            (ref) => _WeddingServiceStepNotifier(ref),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HomeDesignFlow()),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('How would you like to get your dress?'),
      findsOneWidget,
    );
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Buy'), findsOneWidget);
    expect(find.text('Design it yourself'), findsNothing);
    expect(find.text('Finished product'), findsNothing);
  });

  testWidgets('WeddingDressDetailScreen hides Rent/Buy toggles', (tester) async {
    const dress = WeddingDress(
      id: 'dress-1',
      labelEn: 'Classic Tiffany',
      labelAr: 'تيفاني كلاسيك',
      category: 'wedding_dress',
      imageUrl: 'https://example.com/dress.png',
      rentPricePerDay: 50,
      salePrice: 1200,
      insuranceDeposit: 200,
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WeddingDressDetailScreen(
            dress: dress,
            fulfillment: WeddingFulfillment.rent,
          ),
        ),
      ),
    );

    expect(find.text('Classic Tiffany'), findsWidgets);
    expect(find.text('Rent dress'), findsOneWidget);
    expect(find.text('Rental days'), findsOneWidget);
    // Fulfillment toggles removed — only one Rent label (CTA), not toggle pair.
    expect(find.text('Buy'), findsNothing);
  });

  testWidgets('editor bottom panel no longer shows Wedding tab', (tester) async {
    if (!kFeatureConfiguratorBuild) return;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const Scaffold(
                  body: Text('Design editor'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Wedding'), findsNothing);
  });
}

class _WeddingServiceStepNotifier extends HomeFlowNotifier {
  _WeddingServiceStepNotifier(super.ref) {
    state = const HomeFlowSelection(
      gender: UserGenderPreference.women,
      style: HomeStyleLane.wedding,
    );
  }
}
