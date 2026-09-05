import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:id3/id3.dart';
import 'package:path/path.dart' as p;
import '../storage/database_service.dart';
import 'library_scanner.dart';
import 'song_model.dart';

class LinuxLibraryScanner implements LibraryScanner {
  static const Set<String> _supportedExtensions = {
    '.mp3',
    '.flac',
    '.wav',
    '.m4a',
    '.ogg',
  };

  final DatabaseService _dbService = DatabaseService();

  @override
  Future<List<Song>> scanLibrary({List<String>? directories}) async {
    final dirsToScan = directories ?? _getDefaultDirectories();
    final List<Song> songs = [];
    final Set<String> seenPaths = {};

    // 1. Fetch cached modification times and existing songs from SQLite
    final cachedModifiedTimes = await _dbService.getCachedFileModifiedTimes();
    final cachedSongs = await _dbService.getAllSongs();
    final Map<String, Song> cachedMap = {
      for (final s in cachedSongs) s.filePath: s
    };

    final List<Song> songsToSave = [];

    for (final dirPath in dirsToScan) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;

      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final ext = p.extension(entity.path).toLowerCase();
            if (_supportedExtensions.contains(ext) && !seenPaths.contains(entity.path)) {
              seenPaths.add(entity.path);

              try {
                final stat = await entity.stat();
                final fileMod = stat.modified.millisecondsSinceEpoch;

                // Incremental optimization: if file hasn't changed, reuse cached record!
                if (cachedModifiedTimes[entity.path] == fileMod &&
                    cachedMap.containsKey(entity.path)) {
                  songs.add(cachedMap[entity.path]!);
                } else {
                  // New or modified file: parse metadata and extract cover art
                  final song = await _parseFile(entity, ext, fileMod);
                  songs.add(song);
                  songsToSave.add(song);
                }
              } catch (_) {
                // Degrade gracefully on single file parse error
                final fallback = _fallbackSong(entity.path);
                songs.add(fallback);
                songsToSave.add(fallback);
              }
            }
          }
        }
      } catch (e) {
        // Continue to next directory if access error
      }
    }

    // 2. Persist new/updated songs into SQLite
    if (songsToSave.isNotEmpty) {
      await _dbService.saveSongs(songsToSave);
    }

    // 3. Prune songs from SQLite that were deleted on disk
    await _dbService.pruneMissingSongs(seenPaths);

    // Sort songs alphabetically by title
    songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return songs;
  }

  @override
  Future<Uint8List?> getArtwork(Song song) async {
    if (song.embeddedArt != null) {
      return song.embeddedArt;
    }

    // If artPath exists on disk, read from cached file
    if (song.artPath != null) {
      final artFile = File(song.artPath!);
      if (await artFile.exists()) {
        try {
          return await artFile.readAsBytes();
        } catch (_) {}
      }
    }

    // Otherwise extract from MP3 if possible
    try {
      final file = File(song.filePath);
      if (await file.exists() && song.filePath.toLowerCase().endsWith('.mp3')) {
        final bytes = await file.readAsBytes();
        final mp3 = MP3Instance(bytes);
        if (mp3.parseTagsSync()) {
          final tags = mp3.getMetaTags();
          if (tags != null && tags['APIC'] is Map) {
            final apic = tags['APIC'] as Map;
            final base64Str = apic['base64'] as String?;
            if (base64Str != null && base64Str.isNotEmpty) {
              final artBytes = base64Decode(base64Str);
              // Save to cache for future fast loads
              await _dbService.saveArtBytes(song.id, artBytes);
              return artBytes;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  List<String> _getDefaultDirectories() {
    final home = Platform.environment['HOME'];
    final list = <String>[];
    if (home != null) {
      final music = p.join(home, 'Music');
      if (Directory(music).existsSync()) {
        list.add(music);
      } else {
        list.add(home);
      }
    }
    return list;
  }

  Future<Song> _parseFile(File file, String extension, int fileMod) async {
    final filePath = file.path;
    final id = Song.generateId(filePath);

    String title = '';
    String artist = '';
    String album = '';
    Duration duration = Duration.zero;
    int? trackNumber;
    Uint8List? artBytes;
    String? savedArtPath;

    if (extension == '.mp3') {
      try {
        final durMs = _estimateMp3DurationMs(file);
        if (durMs != null) {
          duration = Duration(milliseconds: durMs);
        }

        final bytes = await file.readAsBytes();
        final mp3 = MP3Instance(bytes);
        if (mp3.parseTagsSync()) {
          final tags = mp3.getMetaTags();
          if (tags != null) {
            title = (tags['Title'] as String?)?.trim() ?? '';
            artist = (tags['Artist'] as String?)?.trim() ?? '';
            album = (tags['Album'] as String?)?.trim() ?? '';
            final trackStr = tags['Track'] as String?;
            if (trackStr != null) {
              trackNumber = int.tryParse(trackStr.split('/').first.trim());
            }

            // Extract APIC if present
            if (tags['APIC'] is Map) {
              final apic = tags['APIC'] as Map;
              final b64 = apic['base64'] as String?;
              if (b64 != null && b64.isNotEmpty) {
                artBytes = base64Decode(b64);
                // Cache cover image to disk
                savedArtPath = await _dbService.saveArtBytes(id, artBytes);
              }
            }
          }
        }
      } catch (_) {}
    } else if (extension == '.wav') {
      duration = _estimateWavDuration(file);
    }

    // Fallback metadata from filename if tags are empty/missing
    if (title.isEmpty) {
      final parsed = _parseFilename(filePath);
      title = parsed.title;
      if (artist.isEmpty) artist = parsed.artist;
    }
    if (artist.isEmpty) artist = 'Unknown Artist';
    if (album.isEmpty) album = 'Unknown Album';

    return Song(
      id: id,
      filePath: filePath,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      trackNumber: trackNumber,
      embeddedArt: artBytes,
      artPath: savedArtPath,
      fileModifiedMs: fileMod,
    );
  }

  Song _fallbackSong(String filePath) {
    final parsed = _parseFilename(filePath);
    return Song(
      id: Song.generateId(filePath),
      filePath: filePath,
      title: parsed.title,
      artist: parsed.artist.isNotEmpty ? parsed.artist : 'Unknown Artist',
      album: 'Unknown Album',
      duration: Duration.zero,
    );
  }

  _ParsedName _parseFilename(String filePath) {
    var rawName = p.basenameWithoutExtension(filePath);

    // Clean common rip/download tags
    rawName = rawName.replaceAll(RegExp(r'\(\d+k\)', caseSensitive: false), '');
    rawName = rawName.replaceAll(RegExp(r'\[.*?\]'), '');
    rawName = rawName.replaceAll(RegExp(r'\(official\s*(video|audio)?\)', caseSensitive: false), '');
    rawName = rawName.replaceAll(RegExp(r'\(lyrics?\)', caseSensitive: false), '');
    rawName = rawName.replaceAll('_', ' ');

    // Normalize spacing
    rawName = rawName.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (rawName.contains(' - ')) {
      final parts = rawName.split(' - ');
      final artist = parts[0].trim();
      final title = parts.sublist(1).join(' - ').trim();
      return _ParsedName(artist: artist, title: title);
    }

    return _ParsedName(artist: '', title: rawName.isNotEmpty ? rawName : p.basename(filePath));
  }

  int? _estimateMp3DurationMs(File file) {
    try {
      final raf = file.openSync(mode: FileMode.read);
      final length = raf.lengthSync();
      if (length < 10) {
        raf.closeSync();
        return null;
      }

      final header = raf.readSync(10);
      int offset = 0;
      if (header.length >= 10 &&
          header[0] == 0x49 &&
          header[1] == 0x44 &&
          header[2] == 0x33) {
        final size = (header[6] << 21) |
            (header[7] << 14) |
            (header[8] << 7) |
            header[9];
        offset = 10 + size;
      }

      raf.setPositionSync(offset);
      final buffer = raf.readSync(4096);
      raf.closeSync();

      for (int i = 0; i < buffer.length - 3; i++) {
        if (buffer[i] == 0xFF && (buffer[i + 1] & 0xE0) == 0xE0) {
          final b1 = buffer[i + 1];
          final b2 = buffer[i + 2];
          final versionBits = (b1 >> 3) & 0x03;
          final layerBits = (b1 >> 1) & 0x03;
          final bitrateIndex = (b2 >> 4) & 0x0F;

          if (layerBits == 1 && bitrateIndex > 0 && bitrateIndex < 15) {
            const m1L3 = [
              0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0
            ];
            const m2L3 = [
              0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0
            ];
            final bitrateKbps = (versionBits == 3)
                ? m1L3[bitrateIndex]
                : m2L3[bitrateIndex];

            if (bitrateKbps > 0) {
              final audioBytes = length - offset;
              final durationSeconds = (audioBytes * 8) / (bitrateKbps * 1000);
              return (durationSeconds * 1000).round();
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Duration _estimateWavDuration(File file) {
    try {
      final raf = file.openSync(mode: FileMode.read);
      final header = raf.readSync(44);
      raf.closeSync();
      if (header.length >= 44) {
        final byteRate = header[28] |
            (header[29] << 8) |
            (header[30] << 16) |
            (header[31] << 24);
        if (byteRate > 0) {
          final fileSize = file.lengthSync();
          final dataBytes = fileSize > 44 ? fileSize - 44 : 0;
          return Duration(seconds: (dataBytes / byteRate).round());
        }
      }
    } catch (_) {}
    return Duration.zero;
  }
}

class _ParsedName {
  final String artist;
  final String title;

  _ParsedName({required this.artist, required this.title});
}
