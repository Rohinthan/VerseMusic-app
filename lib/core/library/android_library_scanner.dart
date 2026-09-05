import 'dart:io';
import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'library_scanner.dart';
import 'song_model.dart';

class AndroidLibraryScanner implements LibraryScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  Future<List<Song>> scanLibrary({List<String>? directories}) async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      return [];
    }

    try {
      final songModels = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      final List<Song> songs = [];
      for (final s in songModels) {
        // Skip files shorter than 10 seconds (ringtones, notification sounds)
        final durMs = s.duration ?? 0;
        if (durMs < 10000) continue;

        songs.add(Song(
          id: s.id.toString(),
          filePath: s.data,
          title: s.title.isNotEmpty ? s.title : s.displayNameWOExt,
          artist: (s.artist != null && s.artist != '<unknown>')
              ? s.artist!
              : 'Unknown Artist',
          album: (s.album != null && s.album != '<unknown>')
              ? s.album!
              : 'Unknown Album',
          duration: Duration(milliseconds: durMs),
          trackNumber: s.track,
        ));
      }
      return songs;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Uint8List?> getArtwork(Song song) async {
    final idInt = int.tryParse(song.id);
    if (idInt == null) return null;

    try {
      return await _audioQuery.queryArtwork(
        idInt,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 500,
        quality: 90,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) return true;

    // Check Android version: if Android 13+ (SDK 33), request audio permission
    final audioStatus = await Permission.audio.status;
    if (audioStatus.isGranted) return true;

    final reqAudio = await Permission.audio.request();
    if (reqAudio.isGranted) return true;

    // Fallback to storage permission for Android <= 12
    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) return true;

    final reqStorage = await Permission.storage.request();
    return reqStorage.isGranted;
  }
}
