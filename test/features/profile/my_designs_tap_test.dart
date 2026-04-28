import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/features/profile/screens/my_designs_screen.dart';

const _design = GarmentDesign(
  id: 'd1',
  name: 'Midnight Thobe',
  garmentType: 'thobe',
  primaryColour: '#162F28',
);

void main() {
  testWidgets('tapping a design tile pushes /editor with the design extra',
      (tester) async {
    Object? capturedExtra;
    final router = GoRouter(
      initialLocation: '/profile/designs',
      routes: [
        GoRoute(
          path: '/profile/designs',
          builder: (_, __) => const MyDesignsScreen(),
        ),
        GoRoute(
          path: '/editor',
          builder: (context, state) {
            capturedExtra = state.extra;
            return const Scaffold(body: Text('EDITOR-OPEN'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myDesignsProvider.overrideWith(() => _FakeMyDesignsNotifier()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Midnight Thobe'), findsOneWidget);
    // Tile shows the design name and garment type.
    await tester.tap(find.text('Midnight Thobe'));
    await tester.pumpAndSettle();

    expect(find.text('EDITOR-OPEN'), findsOneWidget);
    expect(capturedExtra, isA<GarmentDesign>());
    expect((capturedExtra! as GarmentDesign).id, 'd1');
  });

  testWidgets('FAB label reads "New design"', (tester) async {
    final router = GoRouter(
      initialLocation: '/profile/designs',
      routes: [
        GoRoute(
          path: '/profile/designs',
          builder: (_, __) => const MyDesignsScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myDesignsProvider.overrideWith(() => _FakeMyDesignsNotifier()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('New design'), findsOneWidget);
  });
}

class _FakeMyDesignsNotifier extends MyDesignsNotifier {
  @override
  Future<List<GarmentDesign>> build() async => const [_design];
}
