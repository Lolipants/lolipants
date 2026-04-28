import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the ordered list of absolute file paths for the in-app music
/// queue (user-selected files from device storage).
class MusicLibraryStorage {
  /// Creates storage backed by [prefs].
  MusicLibraryStorage(this._prefs);

  static const _key = 'music_library_paths_v1';

  final SharedPreferences _prefs;

  /// Reads saved paths (may point to files that were later deleted).
  List<String> readPaths() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } on Object {
      return [];
    }
  }

  /// Persists the queue; paths should already be pruned to existing files.
  Future<void> writePaths(List<String> paths) async {
    await _prefs.setString(_key, jsonEncode(paths));
  }
}
