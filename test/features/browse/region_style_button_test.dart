import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/widgets/region_style_button.dart';

void main() {
  testWidgets('RegionStyleButton renders title + subtitle and fires onTap',
      (tester) async {
    var tapped = 0;
    const preset = RegionStylePreset(
      id: 'qa_thobe',
      title: 'Qatari Thobe',
      subtitle: 'Thobe · Bisht · Abaya',
      region: Region.gulf,
      garmentType: 'thobe',
      primaryColour: Color(0xFFF2E9D2),
      accentColour: Color(0xFFC9A84C),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegionStyleButton(
            preset: preset,
            onTap: () => tapped++,
          ),
        ),
      ),
    );

    expect(find.text('Qatari Thobe'), findsOneWidget);
    expect(find.text('Thobe · Bisht · Abaya'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.byType(RegionStyleButton));
    await tester.pump();
    expect(tapped, 1);
  });

  test('kRegionPresets covers each region', () {
    for (final region in Region.values) {
      final matches = regionPresetsFor(region);
      expect(matches, isNotEmpty, reason: '$region has no presets');
    }
  });
}
