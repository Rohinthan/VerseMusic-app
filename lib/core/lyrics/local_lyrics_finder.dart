import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../library/song_model.dart';

class LocalLyricsResult {
  final String content;
  final String filePath;

  const LocalLyricsResult({
    required this.content,
    required this.filePath,
  });
}

/// Locates and reads local `.lrc` lyrics files associated with an audio track.
class LocalLyricsFinder {
  /// Searches for a matching `.lrc` file beside or near [song.filePath].
  static Future<LocalLyricsResult?> findLyricsForSong(Song song) async {
    final audioPath = song.filePath;
    if (audioPath.isEmpty) return null;

    final audioFile = File(audioPath);
    final dir = audioFile.parent.path;
    final baseNameNoExt = p.basenameWithoutExtension(audioPath);

    // Candidate file paths in order of preference
    final candidates = [
      p.join(dir, '$baseNameNoExt.lrc'),
      p.join(dir, '$baseNameNoExt.LRC'),
      p.join(dir, 'lyrics', '$baseNameNoExt.lrc'),
      p.join(dir, 'Lyrics', '$baseNameNoExt.lrc'),
      p.join(dir, '$baseNameNoExt.txt'),
    ];

    for (final path in candidates) {
      final file = File(path);
      if (await file.exists()) {
        final content = await _readFileSafely(file);
        if (content != null && content.trim().isNotEmpty) {
          return LocalLyricsResult(content: content, filePath: path);
        }
      }
    }

    // Secondary scan: check for case-insensitive basename match in parent directory
    try {
      final parentDir = Directory(dir);
      if (await parentDir.exists()) {
        final lowerTarget = '$baseNameNoExt.lrc'.toLowerCase();
        await for (final entity in parentDir.list(followLinks: false)) {
          if (entity is File) {
            final fileName = p.basename(entity.path).toLowerCase();
            if (fileName == lowerTarget) {
              final content = await _readFileSafely(entity);
              if (content != null && content.trim().isNotEmpty) {
                return LocalLyricsResult(content: content, filePath: entity.path);
              }
            }
          }
        }
      }
    } catch (_) {
      // Graceful fallback on permission or I/O error
    }

    return null;
  }

  /// Attempts to read text as UTF-8 first, falling back to Latin-1 on encoding errors.
  static Future<String?> _readFileSafely(File file) async {
    try {
      final bytes = await file.readAsBytes();
      try {
        return utf8.decode(bytes);
      } catch (_) {
        return latin1.decode(bytes);
      }
    } catch (_) {
      return null;
    }
  }
}
