import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// A playable track stored on the device (e.g. user-selected MP3 from local
/// storage).
@immutable
class Track {
  /// Stable identifier (we use [filePath] as the id).
  final String id;

  /// Display title (usually derived from the filename).
  final String title;

  /// Display artist line (placeholder when unknown).
  final String artist;

  /// Absolute path to the audio file on the device.
  final String filePath;

  /// Creates a track backed by a filesystem path.
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
  });

  /// Builds metadata from a path returned by the system file picker.
  factory Track.fromFilePath(String path) {
    final base = p.basenameWithoutExtension(path);
    return Track(
      id: path,
      title: base.isEmpty ? 'Track' : base,
      artist: 'Local library',
      filePath: path,
    );
  }
}

/// Observable playback state for the music mini/expanded players.
@immutable
class MusicState {
  /// Whether audio is currently playing.
  final bool isPlaying;

  /// Playback progress in seconds.
  final double progress;

  /// Total track duration in seconds.
  final double duration;

  /// Active queue.
  final List<Track> queue;

  /// Index of the current track in [queue]; `-1` when the queue is empty.
  final int currentIndex;

  /// True while the player is buffering / loading a new source.
  final bool isBuffering;

  /// Creates a music state snapshot.
  const MusicState({
    required this.isPlaying,
    required this.progress,
    required this.duration,
    required this.queue,
    required this.currentIndex,
    this.isBuffering = false,
  });

  /// Initial idle state with an empty queue.
  factory MusicState.idle() {
    return const MusicState(
      isPlaying: false,
      progress: 0,
      duration: 0,
      queue: <Track>[],
      currentIndex: -1,
    );
  }

  /// The track being played right now, or `null` when idle.
  Track? get currentTrack {
    if (currentIndex < 0 || currentIndex >= queue.length) return null;
    return queue[currentIndex];
  }

  /// Whether anything is loaded into the player.
  bool get hasTrack => currentTrack != null;

  /// Returns a copy with the given overrides applied.
  MusicState copyWith({
    bool? isPlaying,
    double? progress,
    double? duration,
    List<Track>? queue,
    int? currentIndex,
    bool? isBuffering,
  }) {
    return MusicState(
      isPlaying: isPlaying ?? this.isPlaying,
      progress: progress ?? this.progress,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isBuffering: isBuffering ?? this.isBuffering,
    );
  }
}
