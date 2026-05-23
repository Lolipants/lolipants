import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/logic/configurator_compat.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';

void main() {
  group('configurator_compat', () {
    final template = ConfiguratorTemplate(
      id: 't1',
      nameEn: 'Test',
      nameAr: 'Test',
      garmentType: 'dress',
      regionTag: 'test',
      sortOrder: 0,
      requiredSlotKeys: const ['bodice', 'sleeve'],
      slots: [
        ConfiguratorSlot(
          id: 'slot_bodice',
          slotKey: 'bodice',
          titleEn: 'Bodice',
          titleAr: 'Bodice',
          sortOrder: 0,
          options: [
            ConfiguratorOption(
              id: 'opt_a',
              optionKey: 'bardot',
              labelEn: 'Bardot',
              labelAr: 'Bardot',
              assetUrl: null,
              metadata: const {
                'excludesOptionKeys': ['long_wine'],
              },
              sortOrder: 0,
            ),
          ],
        ),
        ConfiguratorSlot(
          id: 'slot_sleeve',
          slotKey: 'sleeve',
          titleEn: 'Sleeve',
          titleAr: 'Sleeve',
          sortOrder: 1,
          options: [
            ConfiguratorOption(
              id: 'opt_long',
              optionKey: 'long_wine',
              labelEn: 'Long',
              labelAr: 'Long',
              assetUrl: null,
              metadata: const {},
              sortOrder: 0,
            ),
            ConfiguratorOption(
              id: 'opt_cold',
              optionKey: 'cold_shoulder',
              labelEn: 'Cold',
              labelAr: 'Cold',
              assetUrl: null,
              metadata: const {
                'visibleWhen': {'slotKey': 'bodice', 'optionKey': 'bardot'},
              },
              sortOrder: 1,
            ),
          ],
        ),
      ],
    );

    test('visibleWhen hides incompatible sleeve options', () {
      final hidden = filteredOptionsForSlot(
        template: template,
        selections: const {},
        slot: template.slots[1],
      );
      expect(hidden.map((e) => e.id), ['opt_long']);

      final visible = filteredOptionsForSlot(
        template: template,
        selections: const {'slot_bodice': 'opt_a'},
        slot: template.slots[1],
      );
      expect(visible.map((e) => e.id), contains('opt_cold'));
    });

    test('resolveConfiguratorConflicts clears excluded selections', () {
      final resolved = resolveConfiguratorConflicts(
        template: template,
        selections: const {
          'slot_bodice': 'opt_a',
          'slot_sleeve': 'opt_long',
        },
        slotId: 'slot_bodice',
        optionId: 'opt_a',
      );
      expect(resolved['slot_sleeve'], 'opt_cold');
    });

    test('requiredSlotKeys blocks incomplete selections', () {
      expect(
        configuratorRequiredSlotsFilled(
          template: template,
          selections: const {'slot_bodice': 'opt_a'},
        ),
        isFalse,
      );
      expect(
        configuratorRequiredSlotsFilled(
          template: template,
          selections: const {
            'slot_bodice': 'opt_a',
            'slot_sleeve': 'opt_long',
          },
        ),
        isTrue,
      );
    });

    test('suppressesSlotKeys hides sleeve slot and clears selection', () {
      final halterTemplate = ConfiguratorTemplate(
        id: 't2',
        nameEn: 'Dress',
        nameAr: 'Dress',
        garmentType: 'dress',
        regionTag: 'test',
        sortOrder: 0,
        requiredSlotKeys: const ['bodice', 'sleeve'],
        slots: [
          ConfiguratorSlot(
            id: 'slot_bodice',
            slotKey: 'bodice',
            titleEn: 'Bodice',
            titleAr: 'Bodice',
            sortOrder: 0,
            options: [
              ConfiguratorOption(
                id: 'opt_halter',
                optionKey: 'halter',
                labelEn: 'Halter',
                labelAr: 'Halter',
                assetUrl: null,
                metadata: const {
                  'suppressesSlotKeys': ['sleeve'],
                },
                sortOrder: 0,
              ),
            ],
          ),
          ConfiguratorSlot(
            id: 'slot_sleeve',
            slotKey: 'sleeve',
            titleEn: 'Sleeve',
            titleAr: 'Sleeve',
            sortOrder: 1,
            options: [
              ConfiguratorOption(
                id: 'opt_bishop',
                optionKey: 'bishop',
                labelEn: 'Bishop',
                labelAr: 'Bishop',
                assetUrl: null,
                metadata: const {},
                sortOrder: 0,
              ),
            ],
          ),
        ],
      );

      final resolved = resolveConfiguratorConflicts(
        template: halterTemplate,
        selections: const {
          'slot_bodice': 'opt_halter',
          'slot_sleeve': 'opt_bishop',
        },
        slotId: 'slot_bodice',
        optionId: 'opt_halter',
      );
      expect(resolved['slot_sleeve'], isNull);
      expect(
        activeConfiguratorSlots(
          template: halterTemplate,
          selections: resolved,
        ).map((s) => s.slotKey),
        ['bodice'],
      );
      expect(
        configuratorRequiredSlotsFilled(
          template: halterTemplate,
          selections: resolved,
        ),
        isTrue,
      );
    });

    test('sleeveless option does not render a layer', () {
      final opt = ConfiguratorOption(
        id: 'opt_none',
        optionKey: 'sleeveless',
        labelEn: 'No sleeves',
        labelAr: 'No sleeves',
        assetUrl: null,
        metadata: const {'skipLayerRender': true},
        sortOrder: 0,
      );
      expect(shouldRenderConfiguratorLayer(opt), isFalse);
    });
  });
}
