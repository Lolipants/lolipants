import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/utils/layer_tint.dart';

void main() {
  group('parseTintRole', () {
    test('defaults to primary', () {
      expect(parseTintRole(const {}), ConfiguratorTintRole.primary);
    });

    test('parses accent and none', () {
      expect(
        parseTintRole(const {'tintRole': 'accent'}),
        ConfiguratorTintRole.accent,
      );
      expect(
        parseTintRole(const {'tintRole': 'none'}),
        ConfiguratorTintRole.none,
      );
    });
  });

  group('resolveOptionTintColor', () {
    const template = ConfiguratorTemplate(
      id: 't1',
      nameEn: 'Test',
      nameAr: 'Test',
      garmentType: 'dress',
      regionTag: 'test',
      sortOrder: 0,
      requiredSlotKeys: const [],
      slots: const [],
      layerTintEnabled: true,
    );

    const disabledTemplate = ConfiguratorTemplate(
      id: 't2',
      nameEn: 'Test',
      nameAr: 'Test',
      garmentType: 'dress',
      regionTag: 'test',
      sortOrder: 0,
      requiredSlotKeys: const [],
      slots: const [],
      layerTintEnabled: false,
    );

    const primary = Color(0xFF112233);
    const accent = Color(0xFF445566);

    ConfiguratorOption optionWithRole(String role) => ConfiguratorOption(
          id: 'opt',
          optionKey: 'k',
          labelEn: 'L',
          labelAr: 'L',
          assetUrl: null,
          metadata: {'tintRole': role},
          sortOrder: 0,
        );

    test('returns null when template tint disabled', () {
      expect(
        resolveOptionTintColor(
          option: optionWithRole('primary'),
          template: disabledTemplate,
          primaryColour: primary,
          accentColour: accent,
        ),
        isNull,
      );
    });

    test('returns null for none role', () {
      expect(
        resolveOptionTintColor(
          option: optionWithRole('none'),
          template: template,
          primaryColour: primary,
          accentColour: accent,
        ),
        isNull,
      );
    });

    test('returns primary and accent colours', () {
      expect(
        resolveOptionTintColor(
          option: optionWithRole('primary'),
          template: template,
          primaryColour: primary,
          accentColour: accent,
        ),
        primary,
      );
      expect(
        resolveOptionTintColor(
          option: optionWithRole('accent'),
          template: template,
          primaryColour: primary,
          accentColour: accent,
        ),
        accent,
      );
    });
  });

  group('applyLayerTint', () {
    testWidgets('wraps child with ColorFiltered when tintColor set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: applyLayerTint(
              tintColor: const Color(0xFF123456),
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );

      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets('returns child unchanged when tintColor is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: applyLayerTint(
              tintColor: null,
              child: const SizedBox(key: Key('plain'), width: 10, height: 10),
            ),
          ),
        ),
      );

      expect(find.byType(ColorFiltered), findsNothing);
      expect(find.byKey(const Key('plain')), findsOneWidget);
    });
  });
}
