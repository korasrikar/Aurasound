import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'playback_engine.dart';
import 'playback_queue.dart';
import 'playback_snapshot.dart';
import 'track.dart';

/// App-facing player. Owns the queue, forwards commands to the engine, and
/// notifies listeners (UI) on every state change.
class PlayerController extends ChangeNotifier {
  PlayerController({required PlaybackEngine engine, Random? random})
      : _engine = engine,
        _random = random {
    _subscription = _engine.snapshots.listen(_onSnapshot);
  }

  /// Within this many seconds, "previous" restarts the track instead of going back.
  static const Duration restartThreshold = Duration(seconds: 3);

  final PlaybackEngine _engine;
  final PlaybackQueue _queue = PlaybackQueue();
  final Random? _random;
  late final StreamSubscription<PlaybackSnapshot> _subscription;
  PlaybackSnapshot _snapshot = const PlaybackSnapshot();

  PlaybackSnapshot get snapshot => _snapshot;
  PlaybackQueue get queue => _queue;
  Track? get current => _queue.current;

  Future<void> playTracks(
    List<Track> tracks, {
    int startIndex = 0,
    bool shuffle = false,
  }) async {
    _queue.load(tracks, startIndex: startIndex, shuffle: shuffle, random: _random);
    await _engine.setPlaylist(_queue.playOrder, index: _queue.cursor);
    await _engine.setRepeat(_queue.repeat);
    await _engine.play();
    notifyListeners();
  }

  Future<void> togglePlayPause() =>
      _snapshot.playing ? _engine.pause() : _engine.play();

  Future<void> next() => _engine.skipToNext();

  Future<void> previous() async {
    if (_snapshot.position > restartThreshold) {
      await _engine.seek(Duration.zero);
    } else {
      await _engine.skipToPrevious();
    }
  }

  Future<void> seek(Duration position) => _engine.seek(position);

  Future<void> toggleShuffle() async {
    final wasPlaying = _snapshot.playing;
    _queue.setShuffle(!_queue.shuffle, random: _random);
    // Reordering rebuilds the engine sequence; keep the current position and state.
    await _engine.setPlaylist(
      _queue.playOrder,
      index: _queue.cursor,
      position: _snapshot.position,
    );
    await _engine.setRepeat(_queue.repeat);
    if (wasPlaying) await _engine.play();
    notifyListeners();
  }

  Future<void> cycleRepeat() async {
    _queue.cycleRepeat();
    await _engine.setRepeat(_queue.repeat);
    notifyListeners();
  }

  /// "Play next": inserts without interrupting the current track.
  Future<void> addNext(Track track) async {
    if (_queue.isEmpty) {
      await playTracks([track]);
      return;
    }
    _queue.addNext(track);
    await _engine.insertAt(_queue.cursor + 1, track);
    notifyListeners();
  }

  Future<void> removeFromQueue(int playOrderIndex) async {
    _queue.removeAt(playOrderIndex);
    await _engine.removeAt(playOrderIndex);
    if (_queue.isEmpty) await _engine.setPlaylist(const []);
    notifyListeners();
  }

  void _onSnapshot(PlaybackSnapshot snapshot) {
    _snapshot = snapshot;
    _queue.syncCursor(snapshot.index);
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    unawaited(_engine.dispose());
    super.dispose();
  }
}
