import 'lyric_line.dart';

/// Fast, robust parser for `.lrc` (Lyric) files.
///
/// Supports:
/// - Standard timestamps: `[mm:ss.xx]`, `[mm:ss.xxx]`, `[mm:ss]`, `[mm:ss:xx]`
/// - Multi-timestamp lines: `[00:10.00][00:20.00]Chorus`
/// - Global offset adjustment: `[offset:+/-ms]`
/// - Metadata tags: `[ti:...]`, `[ar:...]`, `[al:...]`, etc.
/// - Unsynchronized plain text fallback if no timestamps exist.
class LrcParser {
  static final RegExp _tagRegex = RegExp(r'^\[([a-zA-Z]+):(.*)\]$');
  static final RegExp _timestampRegex =
      RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]');

  /// Parses raw LRC string content into [ParsedLyrics].
  static ParsedLyrics parse(String content) {
    if (content.trim().isEmpty) {
      return const ParsedLyrics.empty();
    }

    final lines = content.split(RegExp(r'\r?\n'));
    final Map<String, String> tags = {};
    final List<LyricLine> parsedLines = [];
    int offsetMs = 0;

    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      // 1. Check for metadata tags like [ti:Title], [ar:Artist], [offset:+/-500]
      final tagMatch = _tagRegex.firstMatch(trimmed);
      if (tagMatch != null) {
        final key = tagMatch.group(1)!.toLowerCase();
        final value = tagMatch.group(2)!.trim();
        tags[key] = value;

        if (key == 'offset') {
          final parsedOffset = int.tryParse(value);
          if (parsedOffset != null) {
            offsetMs = parsedOffset;
          }
        }
        continue;
      }

      // 2. Extract all timestamps on this line
      final timestampMatches = _timestampRegex.allMatches(trimmed).toList();
      if (timestampMatches.isNotEmpty) {
        // Strip all timestamp brackets to extract lyric text
        final text = trimmed.replaceAll(_timestampRegex, '').trim();

        for (final match in timestampMatches) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final subsecondsStr = match.group(3);

          int milliseconds = 0;
          if (subsecondsStr != null && subsecondsStr.isNotEmpty) {
            if (subsecondsStr.length == 1) {
              milliseconds = int.parse(subsecondsStr) * 100;
            } else if (subsecondsStr.length == 2) {
              milliseconds = int.parse(subsecondsStr) * 10;
            } else {
              milliseconds = int.parse(subsecondsStr.substring(0, 3));
            }
          }

          final rawMs = (minutes * 60 + seconds) * 1000 + milliseconds;
          // Apply offset (bounded to >= 0)
          final adjustedMs = (rawMs + offsetMs).clamp(0, 86400000);
          final timestamp = Duration(milliseconds: adjustedMs);

          parsedLines.add(LyricLine(timestamp: timestamp, text: text));
        }
      }
    }

    // If timestamped lines were found, sort chronologically and return synced lyrics
    if (parsedLines.isNotEmpty) {
      parsedLines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return ParsedLyrics(
        lines: parsedLines,
        tags: tags,
        isSynced: true,
      );
    }

    // Fallback: Plain unsynchronized lyrics (each non-tag line is displayed in order)
    final List<LyricLine> plainLines = [];
    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty || _tagRegex.hasMatch(trimmed)) continue;
      plainLines.add(LyricLine(timestamp: Duration.zero, text: trimmed));
    }

    return ParsedLyrics(
      lines: plainLines,
      tags: tags,
      isSynced: false,
    );
  }
}
