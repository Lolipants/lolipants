import 'package:flutter/material.dart';

/// Discrete text scale for accessibility (applied via [MediaQuery.textScaler]).
enum AppTextScaleOption {
  /// Slightly smaller body copy.
  compact,

  /// Default scale (1.0).
  normal,

  /// Comfortable reading (≈1.12).
  comfortable,

  /// Larger body copy (≈1.24).
  large,
}

extension AppTextScaleOptionX on AppTextScaleOption {
  /// Linear text scale factor for [TextScaler.linear].
  double get textScaleFactor => switch (this) {
        AppTextScaleOption.compact => 0.9,
        AppTextScaleOption.normal => 1.0,
        AppTextScaleOption.comfortable => 1.12,
        AppTextScaleOption.large => 1.24,
      };

  /// Stable string for [SharedPreferences].
  String get storageValue => name;
}

AppTextScaleOption appTextScaleOptionFromStorage(String? raw) {
  switch (raw) {
    case 'compact':
      return AppTextScaleOption.compact;
    case 'comfortable':
      return AppTextScaleOption.comfortable;
    case 'large':
      return AppTextScaleOption.large;
    case 'normal':
    default:
      return AppTextScaleOption.normal;
  }
}

/// App-wide user-facing preferences persisted via [SharedPreferences].
@immutable
class SettingsState {
  /// Creates a settings snapshot.
  const SettingsState({
    required this.locale,
    required this.pushEnabled,
    required this.textScale,
    required this.reduceMotion,
  });

  /// Initial state: English, push off, normal text scale, motion on.
  const SettingsState.initial()
      : locale = const Locale('en'),
        pushEnabled = false,
        textScale = AppTextScaleOption.normal,
        reduceMotion = false;

  /// Current app locale (en / ar).
  final Locale locale;

  /// Whether the user wants push notifications (mirrors prefs + platform).
  final bool pushEnabled;

  /// Text size preset for the whole app.
  final AppTextScaleOption textScale;

  /// When true, prefers reduced motion (disables implicit animations).
  final bool reduceMotion;

  /// Returns a copy with the given overrides applied.
  SettingsState copyWith({
    Locale? locale,
    bool? pushEnabled,
    AppTextScaleOption? textScale,
    bool? reduceMotion,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      textScale: textScale ?? this.textScale,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }
}
