import 'dart:math';

import 'package:aurasound/player/playback_queue.dart';
import 'package:aurasound/player/track.dart';
import 'package:flutter_test/flutter_test.dart';

Track t(String id) => Track(
      id: id,
      title: 'Title $id',
      artist: 'Artist',
      streamUri: Uri.parse('https://example.com/$id.m3u8'),
    );

void main() {
  group('PlaybackQueue ordering', () {
    test('load without shuffle keeps order and starts at startIndex', () {
      final q = PlaybackQueue()..load([t('a'), t('b'), t('c')], startIndex: 1);
      expect(q.current?.id, 'b');
      expect(q.playOrder.map((e) => e.id), ['a', 'b', 'c']);
      expect(q.cursor, 1);
    });

    test('load rejects an out-of-range startIndex', () {
      final q = PlaybackQueue();
      expect(() => q.load([t('a')], startIndex: 3), throwsRangeError);
    });

    test('shuffle keeps the start track first and contains every track once', () {
      final tracks = [for (var i = 0; i < 10; i++) t('$i')];
      final q = PlaybackQueue()
        ..load(tracks, startIndex: 4, shuffle: true, random: Random(7));
      expect(q.current?.id, '4');
      expect(q.playOrder.first.id, '4');
      expect(q.playOrder.toSet(), tracks.toSet());
      expect(q.playOrder.length, tracks.length);
    });

    test('turning shuffle off restores canonical order and keeps the current track', () {
      final tracks = [for (var i = 0; i < 6; i++) t('$i')];
      final q = PlaybackQueue()
        ..load(tracks, startIndex: 2, shuffle: true, random: Random(1));
      q.setShuffle(false);
      expect(q.current?.id, '2');
      expect(q.playOrder.map((e) => e.id), ['0', '1', '2', '3', '4', '5']);
    });
  });

  group('repeat and cursor', () {
    test('cycleRepeat goes off -> all -> one -> off', () {
      final q = PlaybackQueue();
      expect(q.cycleRepeat(), RepeatMode.all);
      expect(q.cycleRepeat(), RepeatMode.one);
      expect(q.cycleRepeat(), RepeatMode.off);
    });

    test('nextCursor respects repeat modes', () {
      final q = PlaybackQueue()..load([t('a'), t('b')], startIndex: 1);
      expect(q.nextCursor, isNull); // end of queue, repeat off
      q.setRepeat(RepeatMode.all);
      expect(q.nextCursor, 0); // wraps
      q.setRepeat(RepeatMode.one);
      expect(q.nextCursor, 1); // stays on the same track
    });

    test('previousCursor wraps only with repeat all', () {
      final q = PlaybackQueue()..load([t('a'), t('b')]);
      expect(q.previousCursor, isNull);
      q.setRepeat(RepeatMode.all);
      expect(q.previousCursor, 1);
    });

    test('syncCursor ignores out-of-range indices', () {
      final q = PlaybackQueue()..load([t('a'), t('b')]);
      q.syncCursor(1);
      expect(q.current?.id, 'b');
      q.syncCursor(-1);
      q.syncCursor(99);
      expect(q.current?.id, 'b');
    });
  });

  group('editing', () {
    test('addNext inserts directly after the current track', () {
      final q = PlaybackQueue()..load([t('a'), t('b')]);
      q.addNext(t('x'));
      expect(q.playOrder.map((e) => e.id), ['a', 'x', 'b']);
      expect(q.current?.id, 'a');
    });

    test('addNext on an empty queue starts a new queue', () {
      final q = PlaybackQueue()..addNext(t('x'));
      expect(q.playOrder.map((e) => e.id), ['x']);
      expect(q.current?.id, 'x');
    });

    test('removing an entry before the cursor moves the cursor back', () {
      final q = PlaybackQueue()..load([t('a'), t('b'), t('c')], startIndex: 2);
      q.removeAt(0);
      expect(q.current?.id, 'c');
      expect(q.cursor, 1);
    });

    test('removing the current entry leaves the cursor on the next track', () {
      final q = PlaybackQueue()..load([t('a'), t('b'), t('c')], startIndex: 1);
      q.removeAt(1);
      expect(q.current?.id, 'c');
      expect(q.playOrder.map((e) => e.id), ['a', 'c']);
    });

    test('removing the last remaining track empties the queue', () {
      final q = PlaybackQueue()..load([t('a')]);
      q.removeAt(0);
      expect(q.isEmpty, isTrue);
      expect(q.current, isNull);
    });
  });
}
