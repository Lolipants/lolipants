import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/preferences/shared_preferences_provider.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/profile/data/user_profile_repository.dart';

/// SharedPreferences key for the shopper's preferred gender lane.
const String kUserGenderPreferenceKey = 'lolipants_user_gender';

/// Known gender preference values saved at sign-up.
abstract final class UserGenderPreference {
  static const String men = 'men';
  static const String women = 'women';
  static const String kids = 'kids';

  static const Set<String> all = {men, women, kids};
}

/// API-backed profile reads/writes for gender.
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(dio: ref.watch(apiDioProvider));
});

/// Persisted gender lane (`men` / `women` / `kids`) chosen during sign-up.
final userGenderProvider =
    StateNotifierProvider<UserGenderNotifier, String?>((ref) {
  return UserGenderNotifier(ref);
});

/// Reads and writes [kUserGenderPreferenceKey] and syncs with D1 via API.
class UserGenderNotifier extends StateNotifier<String?> {
  UserGenderNotifier(this._ref) : super(null) {
    _hydrate();
  }

  final Ref _ref;

  Future<void> _hydrate() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(kUserGenderPreferenceKey);
    if (raw != null && UserGenderPreference.all.contains(raw)) {
      state = raw;
    }
  }

  /// Loads gender from `GET /users/me` when authenticated; falls back to local.
  Future<void> syncFromApi() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final repo = _ref.read(userProfileRepositoryProvider);
    final result = await repo.fetchGender();
    await result.fold(
      (_) async {},
      (gender) async {
        if (gender != null && UserGenderPreference.all.contains(gender)) {
          state = gender;
          await prefs.setString(kUserGenderPreferenceKey, gender);
        } else {
          await prefs.remove(kUserGenderPreferenceKey);
          state = null;
        }
      },
    );
  }

  /// Saves [gender] locally and on the server when possible.
  Future<void> persistGender(String gender) async {
    final key = gender.trim().toLowerCase();
    if (!UserGenderPreference.all.contains(key)) {
      return;
    }
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(kUserGenderPreferenceKey, key);
    state = key;

    final repo = _ref.read(userProfileRepositoryProvider);
    final result = await repo.updateGender(key);
    result.fold((_) {}, (_) {});
  }

  /// Saves [gender] when it is one of [UserGenderPreference.all].
  Future<void> setGender(String gender) async {
    await persistGender(gender);
  }

  /// Clears the stored preference (e.g. on sign-out).
  Future<void> clear() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.remove(kUserGenderPreferenceKey);
    state = null;
  }
}
