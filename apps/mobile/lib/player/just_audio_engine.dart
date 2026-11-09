import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'playback_engine.dart';
import 'playback_queue.dart';
import 'playback_snapshot.dart';
import 'track.dart';

/// Production PlaybackEngine on just_audio (ExoPlayer on Android, AVPlayer on iOS).
///
/// Gapless: the whole play order is one ConcatenatingAudioSource, so the native
/// player moves between tracks without tearing down the decoder.
/// Not yet implemented: crossfade (needs two players with a volume ramp) and
/// equalizer (needs AudioPipeline effects). See apps/mobile/README.md.
class JustAudioEngine implements PlaybackEngine {
  JustAudioEngine({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _subscriptions.addAll([
      _player.playerStateStream.listen((state) {
        _playing = state.playing;
        _status = _mapStatus(state.processingState);
        _emit();
      }),
      _player.positionStream.listen((position) {
        _position = position;
        _emit();
      }),
      _player.durationStream.listen((duration) {
        _duration = duration;
        _emit();
      }),
      _player.currentIndexStream.listen((index) {
        _index = index ?? 0;
        _emit();
      }),
    ]);
  }

  final AudioPlayer _player;
  final StreamController<PlaybackSnapshot> _controller =
      StreamController<PlaybackSnapshot>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  ConcatenatingAudioSource? _source;
  List<Track> _playOrder = const [];

  PlaybackStatus _status = PlaybackStatus.idle;
  bool _playing = false;
  int _index = 0;
  Duration _position = Duration.zero;
  Duration? _duration;

  @override
  Stream<PlaybackSnapshot> get snapshots => _controller.stream;

  @override
  Future<void> setPlaylist(
    List<Track> playOrder, {
    int index = 0,
    Duration position = Duration.zero,
  }) async {
    _playOrder = List.unmodifiable(playOrder);
    if (playOrder.isEmpty) {
      _source = null;
      await _player.stop();
      return;
    }
    final source = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: [for (final track in playOrder) _toSource(track)],
    );
    _source = source;
    await _player.setAudioSource(
      source,
      initialIndex: index,
      initialPosition: position,
    );
  }

  @override
  Future<void> insertAt(int index, Track track) async {
    final source = _source;
    if (source == null) return;
    _playOrder = List.unmodifiable([..._playOrder]..insert(index, track));
    await source.insert(index, _toSource(track));
  }

  @override
  Future<void> removeAt(int index) async {
    final source = _source;
    if (source == null) return;
    _playOrder = List.unmodifiable([..._playOrder]..removeAt(index));
    await source.removeAt(index);
  }

  @override
  Future<void> play() async {
    // play() completes only when playback stops, so it must not be awaited here.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> setRepeat(RepeatMode mode) {
    final loopMode = switch (mode) {
      RepeatMode.off => LoopMode.off,
      RepeatMode.all => LoopMode.all,
      RepeatMode.one => LoopMode.one,
    };
    return _player.setLoopMode(loopMode);
  }

  @override
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0.0, 1.0).toDouble());

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _controller.close();
    await _player.dispose();
  }

  AudioSource _toSource(Track track) =>
      AudioSource.uri(track.streamUri, tag: track.id);

  PlaybackStatus _mapStatus(ProcessingState state) => switch (state) {
        ProcessingState.idle => PlaybackStatus.idle,
        ProcessingState.loading => PlaybackStatus.loading,
        ProcessingState.buffering => PlaybackStatus.buffering,
        ProcessingState.ready => PlaybackStatus.ready,
        ProcessingState.completed => PlaybackStatus.completed,
      };

  void _emit() {
    if (_controller.isClosed) return;
    final trackId = _index >= 0 && _index < _playOrder.length
        ? _playOrder[_index].id
        : null;
    _controller.add(PlaybackSnapshot(
      status: _status,
      playing: _playing,
      index: _index,
      position: _position,
      duration: _duration,
      trackId: trackId,
    ));
  }
}
