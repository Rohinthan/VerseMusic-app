class Artist {
  final String id;
  final String name;
  final int songCount;
  final int albumCount;

  const Artist({
    required this.id,
    required this.name,
    this.songCount = 0,
    this.albumCount = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
