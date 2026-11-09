import 'dart:math';

import 'track.dart';

enum RepeatMode { off, all, one }

/// Pure Dart queue logic: ordering, shuffle, repeat, and cursor bookkeeping.
/// Has no dependency on the audio engine, so it is unit-tested directly.
///
/// Invariant: `_order` is a permutation of indices into `_tracks`, and `_cursor`
/// is a valid position in `_order` whenever the queue is non-empty.
class PlaybackQueue {
  List<Track> _tracks = const [];
  List<int> _order = const [];
  int _cursor = 0;
  bool _shuffle = false;
  RepeatMode _repeat = RepeatMode.off;

  bool get isEmpty => _order.isEmpty;
  int get length => _order.length;
  int get cursor => _cursor;
  bool get shuffle => _shuffle;
  RepeatMode get repeat => _repeat;

  /// The tracks in the order they will play.
  List<Track> get playOrder => [for (final i in _order) _tracks[i]];

  Track? get current => isEmpty ? null : _tracks[_order[_cursor]];

  /// Cursor after advancing one track, honouring repeat. Null means end of queue.
  int? get nextCursor {
    if (isEmpty) return null;
    if (_repeat == RepeatMode.one) return _cursor;
    if (_cursor + 1 < _order.length) return _cursor + 1;
    return _repeat == RepeatMode.all ? 0 : null;
  }

  /// Cursor after stepping back one track. Null means start of queue.
  int? get previousCursor {
    if (isEmpty) return null;
    if (_cursor > 0) return _cursor - 1;
    return _repeat == RepeatMode.all ? _order.length - 1 : null;
  }

  void clear() {
    _tracks = const [];
    _order = const [];
    _cursor = 0;
  }

  /// Replaces the queue. With [shuffle], [startIndex] plays first and the rest is shuffled.
  void load(
    List<Track> tracks, {
    int startIndex = 0,
    bool shuffle = false,
    Random? random,
  }) {
    if (tracks.isEmpty) {
      clear();
      return;
    }
    if (startIndex < 0 || startIndex >= tracks.length) {
      throw RangeError.range(startIndex, 0, tracks.length - 1, 'startIndex');
    }
    _tracks = List.unmodifiable(tracks);
    _shuffle = shuffle;
    _order = _buildOrder(startIndex: startIndex, shuffle: shuffle, random: random);
    _cursor = shuffle ? 0 : startIndex;
  }

  /// Turns shuffle on or off. The current track keeps playing and stays first.
  void setShuffle(bool enabled, {Random? random}) {
    if (enabled == _shuffle) return;
    _shuffle = enabled;
    if (isEmpty) return;
    final currentTrackIndex = _order[_cursor];
    _order = _buildOrder(startIndex: currentTrackIndex, shuffle: enabled, random: random);
    _cursor = enabled ? 0 : currentTrackIndex;
  }

  RepeatMode cycleRepeat() {
    _repeat = RepeatMode.values[(_repeat.index + 1) % RepeatMode.values.length];
    return _repeat;
  }

  void setRepeat(RepeatMode mode) => _repeat = mode;

  /// Inserts [track] directly after the current track ("play next").
  void addNext(Track track) {
    if (isEmpty) {
      load([track]);
      return;
    }
    _tracks = List.unmodifiable([..._tracks, track]);
    _order = [..._order]..insert(_cursor + 1, _tracks.length - 1);
  }

  /// Removes the entry at [orderIndex] (a play-order index) from the queue.
  void removeAt(int orderIndex) {
    if (orderIndex < 0 || orderIndex >= _order.length) {
      throw RangeError.range(orderIndex, 0, _order.length - 1, 'orderIndex');
    }
    final removedTrack = _order[orderIndex];
    _tracks = List.unmodifiable([
      for (var i = 0; i < _tracks.length; i++)
        if (i != removedTrack) _tracks[i],
    ]);
    _order = [
      for (final k in _order)
        if (k != removedTrack) (k > removedTrack ? k - 1 : k),
    ];
    if (_order.isEmpty) {
      clear();
      return;
    }
    if (orderIndex < _cursor) {
      _cursor -= 1;
    } else if (_cursor >= _order.length) {
      _cursor = _order.length - 1;
    }
  }

  /// Keeps the cursor in sync with the audio engine's reported index.
  void syncCursor(int playOrderIndex) {
    if (playOrderIndex < 0 || playOrderIndex >= _order.length) return;
    _cursor = playOrderIndex;
  }

  List<int> _buildOrder({
    required int startIndex,
    required bool shuffle,
    Random? random,
  }) {
    if (!shuffle) {
      return List<int>.generate(_tracks.length, (i) => i);
    }
    final rest = [
      for (var i = 0; i < _tracks.length; i++)
        if (i != startIndex) i,
    ]..shuffle(random ?? Random());
    return [startIndex, ...rest];
  }
}
