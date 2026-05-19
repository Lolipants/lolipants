import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/preferences/shared_preferences_provider.dart';

/// SharedPreferences key for the shopper's preferred gender lane.
const String kUserGenderPreferenceKey = 'lolipants_user_gender';

/// Known gender preference values saved at sign-up.
abstract final class UserGenderPreference {
  static const String men = 'men';
  static const String women = 'women';
  static const String kids = 'kids';

  static const Set<String> all = {men, women, kids};
}

/// Persisted gender lane (`men` / `women` / `kids`) chosen during sign-up.
final userGenderProvider =
    StateNotifierProvider<UserGenderNotifier, String?>((ref) {
  return UserGenderNotifier(ref);
});

/// Reads and writes [kUserGenderPreferenceKey].
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

  /// Saves [gender] when it is one of [UserGenderPreference.all].
  Future<void> setGender(String gender) async {
    final key = gender.trim().toLowerCase();
    if (!UserGenderPreference.all.contains(key)) {
      return;
    }
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(kUserGenderPreferenceKey, key);
    state = key;
  }

  /// Clears the stored preference (e.g. on sign-out).
  Future<void> clear() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.remove(kUserGenderPreferenceKey);
    state = null;
  }
}
