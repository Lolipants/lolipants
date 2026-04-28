import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lolipants/core/preferences/shared_preferences_provider.dart';
import 'package:lolipants/features/music/data/music_library_storage.dart';
import 'package:lolipants/features/music/models/track.dart' show MusicState, Track;

/// Persists the user's chosen audio file paths.
final musicLibraryStorageProvider = Provider<MusicLibraryStorage>(
  (ref) => MusicLibraryStorage(ref.watch(sharedPreferencesProvider)),
);

/// Controls the app-wide [AudioPlayer] singleton.
///
/// Queue entries come from **device storage** (file picker). Paths are saved
/// in [SharedPreferences] and pruned when files disappear.
class MusicNotifier extends StateNotifier<MusicState> {
  /// Creates a music notifier.
  MusicNotifier({required MusicLibraryStorage storage})
      : _storage = storage,
        _player = AudioPlayer(),
        super(MusicState.idle()) {
    _player.playerStateStream.listen((playerState) {
      if (!mounted) return;
      state = state.copyWith(
        isPlaying: playerState.playing,
        isBuffering: playerState.processingState == ProcessingState.buffering ||
            playerState.processingState == ProcessingState.loading,
      );
      if (playerState.processingState == ProcessingState.completed) {
        _advanceOrStop();
      }
    });
    _player.positionStream.listen((position) {
      if (!mounted) return;
      state = state.copyWith(progress: position.inMilliseconds / 1000.0);
    });
    _player.durationStream.listen((duration) {
      if (!mounted || duration == null) return;
      state = state.copyWith(duration: duration.inMilliseconds / 1000.0);
    });
  }

  final MusicLibraryStorage _storage;
  final AudioPlayer _player;
  bool _queueLoaded = false;

  /// Loads saved paths from preferences once per session (filters missing
  /// files). Safe to call from [initState]; later calls are no-ops.
  Future<void> ensureQueueLoaded() async {
    if (_queueLoaded) return;
    _queueLoaded = true;
    if (kIsWeb) return;
    final paths = _storage.readPaths();
    final tracks = <Track>[];
    for (final path in paths) {
      if (await File(path).exists()) {
        tracks.add(Track.fromFilePath(path));
      }
    }
    await _storage.writePaths(tracks.map((t) => t.filePath).toList());
    if (tracks.isEmpty) {
      state = MusicState.idle();
      return;
    }
    state = state.copyWith(queue: tracks, currentIndex: 0);
    await _loadCurrent();
  }

  /// Opens the system file picker so the user can choose one or more audio
  /// files from local storage (MP3, M4A, etc.) and appends them to the queue.
  Future<void> pickAndAddTracks() async {
    if (kIsWeb) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;
    await _mergePickerFiles(result.files);
  }

  Future<void> _mergePickerFiles(List<PlatformFile> files) async {
    final existing = {for (final t in state.queue) t.filePath};
    final newTracks = <Track>[];
    for (final f in files) {
      final path = f.path;
      if (path == null || path.isEmpty) continue;
      if (existing.contains(path)) continue;
      if (await File(path).exists()) {
        newTracks.add(Track.fromFilePath(path));
        existing.add(path);
      }
    }
    if (newTracks.isEmpty) return;
    final merged = [...state.queue, ...newTracks];
    await _storage.writePaths(merged.map((t) => t.filePath).toList());
    final wasEmpty = state.queue.isEmpty;
    final nextIndex = wasEmpty
        ? 0
        : state.currentIndex.clamp(0, merged.length - 1);
    state = state.copyWith(
      queue: merged,
      currentIndex: nextIndex,
    );
    if (wasEmpty) {
      await _loadCurrent();
    }
  }

  /// Plays the track at [index].
  Future<void> playIndex(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    state = state.copyWith(currentIndex: index);
    await _loadCurrent();
    await _player.play();
  }

  /// Toggles play/pause for the current track.
  Future<void> toggle() async {
    if (!state.hasTrack) {
      await ensureQueueLoaded();
      if (!state.hasTrack) return;
    }
    if (state.isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Advance to the next track in the queue, wrapping at the end.
  Future<void> next() async {
    if (state.queue.isEmpty) return;
    final nextIndex = (state.currentIndex + 1) % state.queue.length;
    await playIndex(nextIndex);
  }

  /// Skip back to the previous track, wrapping at the start.
  Future<void> previous() async {
    if (state.queue.isEmpty) return;
    final prevIndex = state.currentIndex <= 0
        ? state.queue.length - 1
        : state.currentIndex - 1;
    await playIndex(prevIndex);
  }

  /// Seeks the underlying player to the given [positionSeconds].
  Future<void> seek(double positionSeconds) async {
    final clamped = positionSeconds.clamp(0.0, state.duration);
    await _player.seek(Duration(milliseconds: (clamped * 1000).round()));
  }

  Future<void> _loadCurrent() async {
    final track = state.currentTrack;
    if (track == null) return;
    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.file(track.filePath)),
      );
    } on Object {
      // File may have been removed or format unsupported.
    }
  }

  void _advanceOrStop() {
    if (state.queue.length <= 1) {
      state = state.copyWith(isPlaying: false, progress: 0);
      return;
    }
    unawaited(next());
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

/// App-wide music player provider. Keep `.autoDispose: false` so audio keeps
/// playing as the user navigates between tabs.
final musicProvider = StateNotifierProvider<MusicNotifier, MusicState>((ref) {
  return MusicNotifier(
    storage: ref.watch(musicLibraryStorageProvider),
  );
});
