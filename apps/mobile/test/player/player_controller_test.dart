import 'package:aurasound/player/playback_queue.dart';
import 'package:aurasound/player/playback_snapshot.dart';
import 'package:aurasound/player/player_controller.dart';
import 'package:aurasound/player/track.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_playback_engine.dart';

Track t(String id) => Track(
      id: id,
      title: 'Title $id',
      artist: 'Artist',
      streamUri: Uri.parse('https://example.com/$id.m3u8'),
    );

/// Lets the controller process engine events emitted on the broadcast stream.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakePlaybackEngine engine;
  late PlayerController controller;

  setUp(() {
    engine = FakePlaybackEngine();
    controller = PlayerController(engine: engine);
  });

  tearDown(() {
    controller.dispose();
  });

  test('playTracks loads the play order at startIndex and starts playback', () async {
    await controller.playTracks([t('a'), t('b'), t('c')], startIndex: 1);
    expect(engine.loadedPlayOrder.map((e) => e.id), ['a', 'b', 'c']);
    expect(engine.loadedIndex, 1);
    expect(engine.calls, contains('play'));
  });

  test('engine index changes keep the queue cursor in sync', () async {
    await controller.playTracks([t('a'), t('b'), t('c')]);
    engine.emit(const PlaybackSnapshot(index: 2, playing: true));
    await settle();
    expect(controller.current?.id, 'c');
  });

  test('toggleShuffle keeps the current track playing and first', () async {
    await controller.playTracks([t('a'), t('b'), t('c'), t('d')], startIndex: 2);
    await controller.toggleShuffle();
    expect(controller.queue.shuffle, isTrue);
    expect(engine.loadedPlayOrder.first.id, 'c');
    expect(engine.loadedIndex, 0);
  });

  test('cycleRepeat updates the queue and forwards the mode to the engine', () async {
    await controller.playTracks([t('a'), t('b')]);
    await controller.cycleRepeat();
    expect(controller.queue.repeat, RepeatMode.all);
    expect(engine.repeat, RepeatMode.all);
    await controller.cycleRepeat();
    expect(engine.repeat, RepeatMode.one);
  });

  test('addNext inserts into the engine right after the current track', () async {
    await controller.playTracks([t('a'), t('b')]);
    await controller.addNext(t('x'));
    expect(engine.calls, contains('insertAt:1'));
    expect(controller.queue.playOrder.map((e) => e.id), ['a', 'x', 'b']);
  });

  test('removeFromQueue removes from both queue and engine', () async {
    await controller.playTracks([t('a'), t('b'), t('c')]);
    await controller.removeFromQueue(1);
    expect(engine.calls, contains('removeAt:1'));
    expect(controller.queue.playOrder.map((e) => e.id), ['a', 'c']);
  });

  test('previous restarts the track when more than 3 seconds in', () async {
    await controller.playTracks([t('a'), t('b')], startIndex: 1);
    engine.emit(const PlaybackSnapshot(index: 1, position: Duration(seconds: 10)));
    await settle();
    await controller.previous();
    expect(engine.calls.last, 'seek');
  });

  test('previous goes to the prior track when near the start', () async {
    await controller.playTracks([t('a'), t('b')], startIndex: 1);
    engine.emit(const PlaybackSnapshot(index: 1, position: Duration(seconds: 1)));
    await settle();
    await controller.previous();
    expect(engine.calls.last, 'previous');
  });
}
