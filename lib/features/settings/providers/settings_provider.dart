import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/push/onesignal_bootstrap.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/settings/data/push_repository.dart';
import 'package:lolipants/features/settings/models/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key for the persisted app locale.
const String kSettingsLocaleKey = 'lolipants_locale';

/// SharedPreferences key for push-notification opt-in state.
const String kSettingsPushEnabledKey = 'lolipants_push_enabled';

/// Discrete text scale (`AppTextScaleOption.storageValue`).
const String kSettingsTextScaleKey = 'lolipants_text_scale';

/// When true, reduce non-essential motion.
const String kSettingsReduceMotionKey = 'lolipants_reduce_motion';

/// Async state for the SharedPreferences handle. Cached so we only open it
/// once per app run.
final _prefsProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// Linear text scale factor for [MaterialApp.builder] / [MediaQuery].
final settingsTextScaleFactorProvider = Provider<double>(
  (ref) => ref.watch(settingsProvider).textScale.textScaleFactor,
);

/// Whether the app should reduce implicit animations.
final settingsReduceMotionProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).reduceMotion,
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
    final textScale = appTextScaleOptionFromStorage(
      prefs.getString(kSettingsTextScaleKey),
    );
    final reduceMotion = prefs.getBool(kSettingsReduceMotionKey) ?? false;
    state = SettingsState(
      locale: Locale(localeCode == 'ar' ? 'ar' : 'en'),
      pushEnabled: pushEnabled,
      textScale: textScale,
      reduceMotion: reduceMotion,
    );
  }

  Future<void> _persistLocale(Locale locale) async {
    final prefs = await _ref.read(_prefsProvider.future);
    await prefs.setString(kSettingsLocaleKey, locale.languageCode);
  }

  Future<void> _persistPush({required bool enabled}) async {
    final prefs = await _ref.read(_prefsProvider.future);
    await prefs.setBool(kSettingsPushEnabledKey, enabled);
  }

  Future<void> _persistTextScale(AppTextScaleOption option) async {
    final prefs = await _ref.read(_prefsProvider.future);
    await prefs.setString(kSettingsTextScaleKey, option.storageValue);
  }

  Future<void> _persistReduceMotion({required bool value}) async {
    final prefs = await _ref.read(_prefsProvider.future);
    await prefs.setBool(kSettingsReduceMotionKey, value);
  }

  /// Updates the active locale and persists it.
  Future<void> setLocale(Locale locale) async {
    await _persistLocale(locale);
    state = state.copyWith(locale: locale);
  }

  /// Updates the text scale preset and persists it.
  Future<void> setTextScale(AppTextScaleOption option) async {
    await _persistTextScale(option);
    state = state.copyWith(textScale: option);
  }

  /// Updates reduce-motion and persists it.
  Future<void> setReduceMotion({required bool value}) async {
    await _persistReduceMotion(value: value);
    state = state.copyWith(reduceMotion: value);
  }

  /// Enables or disables push end-to-end (permission, OneSignal, API, prefs).
  ///
  /// [requestOsPermission]: when enabling, call the OS permission prompt first
  /// (checkout flow). When false, only OneSignal opt-in + register run.
  ///
  /// [persistWhenOneSignalMissing]: when enabling without a configured SDK,
  /// still persist the user preference (used after checkout opt-in attempt).
  ///
  /// Returns `false` when enabling was aborted (permission denied, or SDK
  /// missing and [persistWhenOneSignalMissing] is false).
  Future<bool> applyPushPreference({
    required bool want,
    bool requestOsPermission = false,
    bool persistWhenOneSignalMissing = false,
  }) async {
    if (want) {
      if (requestOsPermission) {
        final granted = await requestPushPermission();
        if (!granted) {
          return false;
        }
      }

      final configured = isOneSignalAppConfigured();
      if (!configured) {
        if (persistWhenOneSignalMissing) {
          await _persistPush(enabled: true);
          state = state.copyWith(pushEnabled: true);
        }
        return persistWhenOneSignalMissing;
      }

      await setOneSignalPushOptIn(want: true);
      await _persistPush(enabled: true);
      state = state.copyWith(pushEnabled: true);

      final playerId = await currentPlayerId();
      if (playerId != null && playerId.isNotEmpty) {
        final auth = _ref.read(authProvider);
        if (auth case AsyncData(:final value) when value is AuthAuthenticated) {
          await _ref.read(pushRepositoryProvider).registerPlayerId(playerId);
        }
      }
      return true;
    }

    await setOneSignalPushOptIn(want: false);

    final auth = _ref.read(authProvider);
    if (auth case AsyncData(:final value) when value is AuthAuthenticated) {
      await _ref.read(pushRepositoryProvider).clearPushToken();
    }

    await _persistPush(enabled: false);
    state = state.copyWith(pushEnabled: false);
    return true;
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
