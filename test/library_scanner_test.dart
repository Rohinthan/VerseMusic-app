import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/library/linux_library_scanner.dart';
import 'package:musicapp/core/library/song_model.dart';

import 'package:musicapp/core/storage/database_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationSupportPath() async {
    final dir = Directory('/tmp/verse_music_test');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProviderPlatform();
    await DatabaseService.initialize();
  });
  group('Song Model Tests', () {
    test('generateId creates deterministic and consistent hash', () {
      final id1 = Song.generateId('/home/music/track1.mp3');
      final id2 = Song.generateId('/home/music/track1.mp3');
      final id3 = Song.generateId('/home/music/track2.mp3');

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
      expect(id1.length, equals(32)); // MD5 hex length
    });

    test('Song serialization roundtrip preserves attributes', () {
      const song = Song(
        id: 'test-id',
        filePath: '/path/song.mp3',
        title: 'Title',
        artist: 'Artist',
        album: 'Album',
        duration: Duration(seconds: 180),
        trackNumber: 2,
      );

      final map = song.toMap();
      final fromMap = Song.fromMap(map);

      expect(fromMap.id, equals(song.id));
      expect(fromMap.filePath, equals(song.filePath));
      expect(fromMap.title, equals(song.title));
      expect(fromMap.artist, equals(song.artist));
      expect(fromMap.album, equals(song.album));
      expect(fromMap.duration, equals(song.duration));
      expect(fromMap.trackNumber, equals(song.trackNumber));
    });
  });

  group('LinuxLibraryScanner Tests', () {
    test('scans real files if ~/Music/musics exists', () async {
      final musicDir = Directory('/home/raccoon/Music/musics');
      if (await musicDir.exists()) {
        final scanner = LinuxLibraryScanner();
        final songs = await scanner.scanLibrary(directories: [musicDir.path]);

        expect(songs, isNotEmpty);
        expect(songs.first.filePath, startsWith(musicDir.path));
        expect(songs.first.title, isNotEmpty);
        expect(songs.first.artist, isNotEmpty);
        expect(songs.first.id, isNotEmpty);
      }
    });

    test('gracefully handles non-existent directories', () async {
      final scanner = LinuxLibraryScanner();
      final songs = await scanner.scanLibrary(directories: ['/non/existent/path/123']);
      expect(songs, isEmpty);
    });
  });
}
