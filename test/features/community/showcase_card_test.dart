import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/constants/community_strings.dart';
import 'package:lolipants/features/community/models/showcase_item.dart';
import 'package:lolipants/features/community/widgets/showcase_card.dart';

ShowcaseItem _item({bool pro = true}) {
  return ShowcaseItem(
    designId: 'design-1',
    name: 'Midnight Thobe',
    garmentType: 'thobe',
    primaryColour: '#0A1A2F',
    accentColour: '#C9A14A',
    previewImageUrl: null,
    orderCount: 4,
    createdAt: DateTime(2026, 4, 10),
    designer: ShowcaseDesignerMini(
      id: 'designer-1',
      name: 'Nora Designer',
      isProDesigner: pro,
    ),
  );
}

Future<void> _pumpShowcaseCard(
  WidgetTester tester, {
  required ShowcaseItem item,
  required VoidCallback onTap,
  required VoidCallback onOrder,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 420,
              child: ShowcaseCard(
                item: item,
                onTap: onTap,
                onOrder: onOrder,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders design name, garment, designer line, and Order this',
      (tester) async {
    await _pumpShowcaseCard(
      tester,
      item: _item(),
      onTap: () {},
      onOrder: () {},
    );

    expect(find.text('Midnight Thobe'), findsOneWidget);
    expect(find.text('thobe'), findsOneWidget);
    expect(
      find.text('${CommunityStrings.byDesigner} Nora Designer'),
      findsOneWidget,
    );
    expect(find.text(CommunityStrings.orderThis), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });

  testWidgets('tapping the Order this button fires onOrder (and not onTap)',
      (tester) async {
    var orders = 0;
    var opens = 0;
    await _pumpShowcaseCard(
      tester,
      item: _item(pro: false),
      onTap: () => opens += 1,
      onOrder: () => orders += 1,
    );

    await tester.tap(find.text(CommunityStrings.orderThis));
    await tester.pump();
    expect(orders, 1);
    expect(opens, 0);
    expect(find.byIcon(Icons.verified), findsNothing);
  });

  test('parseHexColour handles #RRGGBB, #RGB, and null fallback', () {
    expect(parseHexColour('#0A1A2F').toARGB32(), 0xFF0A1A2F);
    expect(parseHexColour('#FFF').toARGB32(), 0xFFFFFFFF);
    expect(
      parseHexColour(null, fallback: const Color(0xFF123456)).toARGB32(),
      0xFF123456,
    );
  });
}
