import '../player/track.dart';

/// Placeholder catalog for the starter app. Replace with the playback/catalog API.
/// The audio files are public SoundHelix demo tracks, not AuraSound content.
final List<Track> demoTracks = [
  Track(
    id: 'demo-1',
    title: 'Demo Track One',
    artist: 'Demo Artist',
    streamUri: Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
    language: 'en',
  ),
  Track(
    id: 'demo-2',
    title: 'Demo Track Two',
    artist: 'Demo Artist',
    streamUri: Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'),
    language: 'en',
  ),
  Track(
    id: 'demo-3',
    title: 'Demo Track Three',
    artist: 'Demo Artist',
    streamUri: Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'),
    language: 'en',
  ),
];
