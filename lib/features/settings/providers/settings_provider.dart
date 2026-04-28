import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/settings/models/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key for the persisted app locale.
const String kSettingsLocaleKey = 'lolipants_locale';

/// SharedPreferences key for push-notification opt-in state.
const String kSettingsPushEnabledKey = 'lolipants_push_enabled';

/// Async state for the SharedPreferences handle. Cached so we only open it
/// once per app run.
final _prefsProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// App-wide settings notifier. Hydrates from SharedPreferences on first read
/// so UI can react immediately without awaiting a future.
class SettingsNotifier extends StateNotifier<SettingsState> {
  /// Creates a notifier and schedules the hydrate call.
  SettingsNotifier(this._ref) : super(const SettingsState.initial()) {
    _hydrate();
  }

  final Ref _ref;

  Future<void> _hydrate() async {
    final prefs = await _ref.read(_prefsProvider.future);
    final localeCode = prefs.getString(kSettingsLocaleKey) ?? 'en';
    final pushEnabled = prefs.getBool(kSettingsPushEnabledKey) ?? false;
    state = SettingsState(
      locale: Locale(localeCode == 'ar' ? 'ar' : 'en'),
      pushEnabled: pushEnabled,
    );
  }

  /// Updates the active locale and persists it.
  Future<void> setLocale(Locale locale) async {
    final prefs = await _ref.read(_prefsProvider.future);
    await prefs.setString(kSettingsLocaleKey, locale.languageCode);
    state = state.copyWith(locale: locale);
  }

  /// Updates the push-opt-in flag and persists it.
  Future<void> setPushEnabled(bool enabled) async {
    final prefs = await _ref.read(_prefsProvider.future);
    await prefs.setBool(kSettingsPushEnabledKey, enabled);
    state = state.copyWith(pushEnabled: enabled);
  }
}

/// App-wide settings provider.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

/// Convenience selector just for the locale.
final settingsLocaleProvider = Provider<Locale>(
  (ref) => ref.watch(settingsProvider).locale,
);
