import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injected [SharedPreferences] instance (override in `main` after loading).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'sharedPreferencesProvider must be overridden in main() '
        'after SharedPreferences.getInstance().',
  );
});
