/// A playable item. Deliberately small: the full catalog model lives on the server.
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.streamUri,
    this.duration,
    this.language = 'und',
  });

  final String id;
  final String title;
  final String artist;

  /// Signed HLS/DASH manifest or progressive URL returned by the playback API.
  final Uri streamUri;

  final Duration? duration;

  /// BCP-47 language tag, e.g. 'hi', 'te', 'ta', 'en', or 'zxx' for instrumental.
  final String language;

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Track($id, $title)';
}
