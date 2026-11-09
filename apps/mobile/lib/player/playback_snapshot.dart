enum PlaybackStatus { idle, loading, buffering, ready, completed }

/// Immutable view of playback state that the UI renders.
class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.status = PlaybackStatus.idle,
    this.playing = false,
    this.index = 0,
    this.position = Duration.zero,
    this.duration,
    this.trackId,
  });

  final PlaybackStatus status;
  final bool playing;

  /// Index into the current play order (not the user's original order).
  final int index;
  final Duration position;
  final Duration? duration;
  final String? trackId;
}
