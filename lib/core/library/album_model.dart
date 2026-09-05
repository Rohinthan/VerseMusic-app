import 'dart:typed_data';

class Album {
  final String id;
  final String title;
  final String artist;
  final int songCount;
  final Uint8List? artBytes;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.songCount = 0,
    this.artBytes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
