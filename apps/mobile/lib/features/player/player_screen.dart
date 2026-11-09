import 'package:flutter/material.dart';

import '../../player/playback_queue.dart';
import '../../player/playback_snapshot.dart';
import '../../player/player_controller.dart';

/// Mini player shown above the bottom navigation. Hidden when nothing is loaded.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.controller, required this.onOpen});

  final PlayerController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final track = controller.current;
        if (track == null) return const SizedBox.shrink();
        final playing = controller.snapshot.playing;
        return Material(
          elevation: 8,
          child: ListTile(
            onTap: onOpen,
            title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              tooltip: playing ? 'Pause' : 'Play',
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              onPressed: controller.togglePlayPause,
            ),
          ),
        );
      },
    );
  }
}

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final track = controller.current;
        final snap = controller.snapshot;
        final queue = controller.queue;
        final total = snap.duration ?? track?.duration ?? Duration.zero;
        final maxMs = total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1.0;
        final posMs = snap.position.inMilliseconds.toDouble().clamp(0.0, maxMs).toDouble();

        return Scaffold(
          appBar: AppBar(title: const Text('Now playing')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Icon(Icons.album, size: 220, color: scheme.primary),
                  const SizedBox(height: 24),
                  Text(track?.title ?? 'Nothing playing',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(track?.artist ?? '',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Slider(
                    value: posMs,
                    max: maxMs,
                    label: _format(snap.position),
                    onChanged: track == null
                        ? null
                        : (v) => controller.seek(Duration(milliseconds: v.round())),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_format(snap.position)),
                      Text(_format(total)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        tooltip: 'Shuffle',
                        icon: const Icon(Icons.shuffle),
                        color: queue.shuffle ? scheme.primary : null,
                        onPressed: controller.toggleShuffle,
                      ),
                      IconButton(
                        tooltip: 'Previous',
                        iconSize: 40,
                        icon: const Icon(Icons.skip_previous),
                        onPressed: controller.previous,
                      ),
                      IconButton.filled(
                        tooltip: snap.playing ? 'Pause' : 'Play',
                        iconSize: 40,
                        icon: Icon(snap.playing ? Icons.pause : Icons.play_arrow),
                        onPressed: controller.togglePlayPause,
                      ),
                      IconButton(
                        tooltip: 'Next',
                        iconSize: 40,
                        icon: const Icon(Icons.skip_next),
                        onPressed: controller.next,
                      ),
                      IconButton(
                        tooltip: 'Repeat: ${queue.repeat.name}',
                        color: queue.repeat == RepeatMode.off ? null : scheme.primary,
                        icon: Icon(_repeatIcon(queue.repeat)),
                        onPressed: controller.cycleRepeat,
                      ),
                    ],
                  ),
                  Text(_statusLabel(snap.status),
                      style: Theme.of(context).textTheme.labelSmall),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: queue.length,
                      itemBuilder: (context, i) {
                        final item = queue.playOrder[i];
                        final isCurrent = i == queue.cursor;
                        return ListTile(
                          dense: true,
                          selected: isCurrent,
                          title: Text(item.title),
                          subtitle: Text(item.artist),
                          trailing: IconButton(
                            tooltip: 'Remove from queue',
                            icon: const Icon(Icons.close),
                            onPressed: () => controller.removeFromQueue(i),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static IconData _repeatIcon(RepeatMode mode) => switch (mode) {
        RepeatMode.off => Icons.repeat,
        RepeatMode.all => Icons.repeat,
        RepeatMode.one => Icons.repeat_one,
      };

  static String _statusLabel(PlaybackStatus status) => switch (status) {
        PlaybackStatus.idle => '',
        PlaybackStatus.loading => 'Loading...',
        PlaybackStatus.buffering => 'Buffering...',
        PlaybackStatus.ready => '',
        PlaybackStatus.completed => 'Finished',
      };

  static String _format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
