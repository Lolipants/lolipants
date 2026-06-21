import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/core/preferences/shared_preferences_provider.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/home/logic/home_featured_designs.dart';
import 'package:lolipants/features/home/models/home_flow_selection.dart';
import 'package:lolipants/features/home/providers/home_featured_presets_provider.dart';
import 'package:lolipants/features/home/providers/home_flow_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildHomeFeaturedDesigns', () {
    test('women lane excludes mens look paths', () {
      final featured = buildHomeFeaturedDesigns(
        gender: UserGenderPreference.women,
        cmsItems: const [],
        count: 8,
      );

      expect(featured, isNotEmpty);
      for (final preset in featured) {
        final path = preset.resolvedPreviewAssetPath ?? '';
        expect(path.contains('design_mens_look'), isFalse);
        expect(path.contains('design_mod_mens_'), isFalse);
      }
    });

    test('men lane uses mens bundled paths only', () {
      final featured = buildHomeFeaturedDesigns(
        gender: UserGenderPreference.men,
        cmsItems: const [],
        count: 8,
      );

      expect(featured, isNotEmpty);
      for (final preset in featured) {
        final path = preset.resolvedPreviewAssetPath ?? '';
        expect(path.contains('design_mens_look'), isTrue);
      }
    });

    test('kids lane maps to women picks', () {
      expect(
        effectiveFeaturedGenderLane(UserGenderPreference.kids),
        UserGenderPreference.women,
      );
    });
  });

  group('effectiveHomeFeaturedGenderProvider', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('prefers wizard gender over profile', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          homeFlowSelectionProvider.overrideWith(
            (ref) => _MenFlowNotifier(ref),
          ),
          userGenderProvider.overrideWith((ref) {
            final n = UserGenderNotifier(ref);
            n.state = UserGenderPreference.women;
            return n;
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(effectiveHomeFeaturedGenderProvider),
        UserGenderPreference.men,
      );
    });
  });

  group('homeFeaturedPresetsProvider', () {
    test('returns empty when gender is unknown', () {
      final container = ProviderContainer(
        overrides: [
          homeGenderSyncProvider.overrideWith((ref) async {}),
          designCatalogItemsProvider.overrideWith((ref) async => const []),
          effectiveHomeFeaturedGenderProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(homeFeaturedPresetsProvider), isEmpty);
    });

    test('returns up to four mens picks when gender is men', () {
      final container = ProviderContainer(
        overrides: [
          homeGenderSyncProvider.overrideWith((ref) async {}),
          designCatalogItemsProvider.overrideWith((ref) async => const []),
          effectiveHomeFeaturedGenderProvider.overrideWith(
            (ref) => UserGenderPreference.men,
          ),
        ],
      );
      addTearDown(container.dispose);

      final presets = container.read(homeFeaturedPresetsProvider);
      expect(presets, isNotEmpty);
      expect(presets.length, lessThanOrEqualTo(4));
      for (final preset in presets) {
        final path = preset.resolvedPreviewAssetPath ?? '';
        expect(path.contains('design_mens_look'), isTrue);
      }
    });
  });
}

class _MenFlowNotifier extends HomeFlowNotifier {
  _MenFlowNotifier(super.ref) {
    state = const HomeFlowSelection(gender: UserGenderPreference.men);
  }
}
