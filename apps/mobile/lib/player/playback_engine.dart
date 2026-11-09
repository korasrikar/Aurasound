import 'playback_queue.dart';
import 'playback_snapshot.dart';
import 'track.dart';

/// The seam between app logic and the native audio stack. Implementations:
///   * JustAudioEngine - production (just_audio).
///   * FakePlaybackEngine (tests) - records calls, emits snapshots on demand.
abstract interface class PlaybackEngine {
  /// Broadcast stream of state changes. Must be safe to listen to more than once.
  Stream<PlaybackSnapshot> get snapshots;

  /// Loads [playOrder] as one gapless sequence and positions at [index].
  Future<void> setPlaylist(
    List<Track> playOrder, {
    int index = 0,
    Duration position = Duration.zero,
  });

  /// Inserts into the loaded sequence without interrupting the current track.
  Future<void> insertAt(int index, Track track);

  /// Removes from the loaded sequence without interrupting the current track.
  Future<void> removeAt(int index);

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> setRepeat(RepeatMode mode);
  Future<void> setVolume(double volume);
  Future<void> setSpeed(double speed);
  Future<void> dispose();
}
