import 'package:flutter/foundation.dart';

/// Represents a single synchronized lyric line with a timestamp.
@immutable
class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricLine &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          text == other.text;

  @override
  int get hashCode => timestamp.hashCode ^ text.hashCode;

  @override
  String toString() =>
      '[${timestamp.inMinutes}:${(timestamp.inSeconds % 60).toString().padLeft(2, '0')}.${(timestamp.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}] $text';
}

/// Represents the complete parsed lyrics document, supporting both
/// timestamp-synchronized and plain unsynchronized lyrics.
@immutable
class ParsedLyrics {
  final List<LyricLine> lines;
  final Map<String, String> tags;
  final bool isSynced;

  const ParsedLyrics({
    required this.lines,
    this.tags = const {},
    this.isSynced = true,
  });

  const ParsedLyrics.empty()
      : lines = const [],
        tags = const {},
        isSynced = false;

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;

  /// Fast binary search to find the active line index corresponding to [position].
  /// Returns -1 if playback is before the first lyric line or if lyrics are empty.
  int getActiveLineIndex(Duration position) {
    if (lines.isEmpty) return -1;
    if (position < lines.first.timestamp) return -1;

    int low = 0;
    int high = lines.length - 1;
    int result = -1;

    while (low <= high) {
      final mid = (low + high) >> 1;
      if (lines[mid].timestamp <= position) {
        result = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return result;
  }
}
