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
              metadata: const {'requiresSleeveless': true},
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
              id: 'opt_none',
              optionKey: 'sleeveless',
              labelEn: 'No sleeves',
              labelAr: 'No sleeves',
              assetUrl: null,
              metadata: const {'skipLayerRender': true},
              sortOrder: 0,
            ),
            ConfiguratorOption(
              id: 'opt_long',
              optionKey: 'long_wine',
              labelEn: 'Long',
              labelAr: 'Long',
              assetUrl: null,
              metadata: const {},
              sortOrder: 1,
            ),
            ConfiguratorOption(
              id: 'opt_cold',
              optionKey: 'cold_shoulder',
              labelEn: 'Cold',
              labelAr: 'Cold',
              assetUrl: null,
              metadata: const {},
              sortOrder: 2,
            ),
          ],
        ),
      ],
    );

    test('off-shoulder bodice only allows no-sleeves in picker', () {
      final allSleeves = filteredOptionsForSlot(
        template: template,
        selections: const {},
        slot: template.slots[1],
      );
      expect(allSleeves.map((e) => e.id), ['opt_none', 'opt_long', 'opt_cold']);

      final withBardot = filteredOptionsForSlot(
        template: template,
        selections: const {'slot_bodice': 'opt_a'},
        slot: template.slots[1],
      );
      expect(withBardot.map((e) => e.id), ['opt_none']);
    });

    test('resolveConfiguratorConflicts couples bardot with sleeveless', () {
      final resolved = resolveConfiguratorConflicts(
        template: template,
        selections: const {
          'slot_bodice': 'opt_a',
          'slot_sleeve': 'opt_long',
        },
        slotId: 'slot_bodice',
        optionId: 'opt_a',
      );
      expect(resolved['slot_sleeve'], 'opt_none');
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
            'slot_sleeve': 'opt_none',
          },
        ),
        isTrue,
      );
    });

    test('halter bodice couples to sleeveless and keeps sleeve slot', () {
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
                metadata: const {'requiresSleeveless': true},
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
                id: 'opt_none',
                optionKey: 'sleeveless',
                labelEn: 'No sleeves',
                labelAr: 'No sleeves',
                assetUrl: null,
                metadata: const {'skipLayerRender': true},
                sortOrder: 0,
              ),
              ConfiguratorOption(
                id: 'opt_bishop',
                optionKey: 'bishop',
                labelEn: 'Bishop',
                labelAr: 'Bishop',
                assetUrl: null,
                metadata: const {},
                sortOrder: 1,
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
      expect(resolved['slot_sleeve'], 'opt_none');
      expect(
        activeConfiguratorSlots(
          template: halterTemplate,
          selections: resolved,
        ).map((s) => s.slotKey),
        ['bodice', 'sleeve'],
      );
      expect(
        filteredOptionsForSlot(
          template: halterTemplate,
          selections: resolved,
          slot: halterTemplate.slots[1],
        ).map((o) => o.id),
        ['opt_none'],
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

    test('ai layer notes warn when sleeveless and describe overlay panels', () {
      final overlayTemplate = ConfiguratorTemplate(
        id: 'modest',
        nameEn: 'Modest',
        nameAr: 'Modest',
        garmentType: 'abaya',
        regionTag: 'gulf',
        sortOrder: 0,
        requiredSlotKeys: const ['sleeve_length', 'overlay_panel'],
        slots: [
          ConfiguratorSlot(
            id: 'slot_sleeve',
            slotKey: 'sleeve_length',
            titleEn: 'Sleeves',
            titleAr: 'Sleeves',
            sortOrder: 0,
            options: [
              ConfiguratorOption(
                id: 'opt_none',
                optionKey: 'sleeveless',
                labelEn: 'No sleeves',
                labelAr: 'No sleeves',
                assetUrl: null,
                metadata: const {'skipLayerRender': true},
                sortOrder: 0,
              ),
            ],
          ),
          ConfiguratorSlot(
            id: 'slot_overlay',
            slotKey: 'overlay_panel',
            titleEn: 'Overlay',
            titleAr: 'Overlay',
            sortOrder: 1,
            options: [
              ConfiguratorOption(
                id: 'opt_chest',
                optionKey: 'chest_maroon',
                labelEn: 'Chest panel',
                labelAr: 'Chest panel',
                assetUrl: null,
                metadata: const {},
                sortOrder: 0,
              ),
            ],
          ),
        ],
      );

      final notes = configuratorAiLayerNotesText(
        template: overlayTemplate,
        selections: const {
          'slot_sleeve': 'opt_none',
          'slot_overlay': 'opt_chest',
        },
      );

      expect(notes, contains('NO SLEEVES'));
      expect(notes, contains('Chest panel'));
      expect(notes, contains('NOT sleeves'));
      expect(notes, contains('front-torso'));
    });
  });
}
