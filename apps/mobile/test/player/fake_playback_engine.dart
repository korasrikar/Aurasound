import 'dart:async';

import 'package:aurasound/player/playback_engine.dart';
import 'package:aurasound/player/playback_queue.dart';
import 'package:aurasound/player/playback_snapshot.dart';
import 'package:aurasound/player/track.dart';

/// Records commands so tests can assert what the controller asked the engine to do.
class FakePlaybackEngine implements PlaybackEngine {
  final StreamController<PlaybackSnapshot> _controller =
      StreamController<PlaybackSnapshot>.broadcast();

  final List<String> calls = [];
  List<Track> loadedPlayOrder = const [];
  int loadedIndex = -1;
  RepeatMode? repeat;

  void emit(PlaybackSnapshot snapshot) => _controller.add(snapshot);

  @override
  Stream<PlaybackSnapshot> get snapshots => _controller.stream;

  @override
  Future<void> setPlaylist(
    List<Track> playOrder, {
    int index = 0,
    Duration position = Duration.zero,
  }) async {
    calls.add('setPlaylist');
    loadedPlayOrder = List.of(playOrder);
    loadedIndex = index;
  }

  @override
  Future<void> insertAt(int index, Track track) async {
    calls.add('insertAt:$index');
    loadedPlayOrder.insert(index, track);
  }

  @override
  Future<void> removeAt(int index) async {
    calls.add('removeAt:$index');
    loadedPlayOrder.removeAt(index);
  }

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> seek(Duration position) async => calls.add('seek');

  @override
  Future<void> skipToNext() async => calls.add('next');

  @override
  Future<void> skipToPrevious() async => calls.add('previous');

  @override
  Future<void> setRepeat(RepeatMode mode) async {
    calls.add('setRepeat:${mode.name}');
    repeat = mode;
  }

  @override
  Future<void> setVolume(double volume) async => calls.add('volume');

  @override
  Future<void> setSpeed(double speed) async => calls.add('speed');

  @override
  Future<void> dispose() => _controller.close();
}
