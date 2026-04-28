import 'package:flutter/material.dart';

/// App-wide user-facing preferences persisted via [SharedPreferences].
@immutable
class SettingsState {
  /// Creates a settings snapshot.
  const SettingsState({
    required this.locale,
    required this.pushEnabled,
  });

  /// Initial state: English, push off (requested on first order).
  const SettingsState.initial()
      : locale = const Locale('en'),
        pushEnabled = false;

  /// Current app locale (en / ar).
  final Locale locale;

  /// Whether the user has accepted push notifications.
  final bool pushEnabled;

  /// Returns a copy with the given overrides applied.
  SettingsState copyWith({Locale? locale, bool? pushEnabled}) {
    return SettingsState(
      locale: locale ?? this.locale,
      pushEnabled: pushEnabled ?? this.pushEnabled,
    );
  }
}
