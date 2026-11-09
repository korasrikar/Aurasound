import 'package:flutter/material.dart';

import '../../player/player_controller.dart';
import '../../player/track.dart';
import '../player/player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller, required this.tracks});

  final PlayerController controller;
  final List<Track> tracks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AuraSound')),
      body: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, i) {
          final track = tracks[i];
          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(track.title),
            subtitle: Text(track.artist),
            trailing: IconButton(
              tooltip: 'Play next',
              icon: const Icon(Icons.playlist_play),
              onPressed: () => controller.addNext(track),
            ),
            onTap: () => controller.playTracks(tracks, startIndex: i),
          );
        },
      ),
      bottomNavigationBar: MiniPlayer(
        controller: controller,
        onOpen: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlayerScreen(controller: controller),
          ),
        ),
      ),
    );
  }
}
