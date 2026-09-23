import 'dart:io';
import 'package:flutter/foundation.dart';
import '../library/song_model.dart';

/// Handles native desktop song-change popup notifications on Linux.
class DesktopNotificationService {
  static bool enabled = true;

  /// Shows a notification bubble at the top of the screen when a new song plays.
  static Future<void> showSongNotification(Song song) async {
    if (!enabled) return;
    if (!Platform.isLinux) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      final List<String> args = [
        '-a',
        'Verse Music',
        '-c',
        'media',
        '-t',
        '3000',
        '-h',
        'string:x-canonical-private-synchronous:verse-playback',
      ];

      if (song.artPath != null && await File(song.artPath!).exists()) {
        args.addAll(['-i', song.artPath!]);
      } else {
        args.addAll(['-i', 'audio-x-generic']);
      }

      final artistInfo = song.artist.isNotEmpty ? song.artist : 'Unknown Artist';
      final albumInfo = song.album.isNotEmpty ? ' • ${song.album}' : '';
      final body = '$artistInfo$albumInfo';

      args.addAll([song.title, body]);

      await Process.run('notify-send', args);
    } catch (e) {
      debugPrint('Desktop notification error: $e');
    }
  }
}
