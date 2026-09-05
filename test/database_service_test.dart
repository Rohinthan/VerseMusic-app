import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/library/song_model.dart';
import 'package:musicapp/core/storage/database_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationSupportPath() async {
    final dir = Directory('/tmp/verse_db_test_${DateTime.now().millisecondsSinceEpoch}');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService dbService;

  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProviderPlatform();
    await DatabaseService.initialize();
  });

  setUp(() {
    dbService = DatabaseService();
  });

  tearDown(() async {
    await dbService.close();
  });

  test('DatabaseService saves and retrieves songs with correct attributes', () async {
    final song1 = Song(
      id: 'song-1',
      filePath: '/music/song1.mp3',
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: const Duration(seconds: 243),
      trackNumber: 1,
      fileModifiedMs: 1690000000,
    );

    final song2 = Song(
      id: 'song-2',
      filePath: '/music/song2.mp3',
      title: 'Wait',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: const Duration(seconds: 343),
      trackNumber: 2,
      fileModifiedMs: 1690000001,
    );

    await dbService.saveSongs([song1, song2]);

    final allSongs = await dbService.getAllSongs();
    expect(allSongs.length, equals(2));
    expect(allSongs.any((s) => s.title == 'Midnight City'), isTrue);
    expect(allSongs.any((s) => s.title == 'Wait'), isTrue);

    // Test albums aggregation
    final albums = await dbService.getAlbums();
    expect(albums.length, equals(1));
    expect(albums.first.title, equals('Hurry Up, We\'re Dreaming'));
    expect(albums.first.songCount, equals(2));

    // Test artists aggregation
    final artists = await dbService.getArtists();
    expect(artists.length, equals(1));
    expect(artists.first.name, equals('M83'));
    expect(artists.first.songCount, equals(2));

    // Test modified times
    final modTimes = await dbService.getCachedFileModifiedTimes();
    expect(modTimes['/music/song1.mp3'], equals(1690000000));

    // Test pruning missing songs
    await dbService.pruneMissingSongs({'/music/song1.mp3'});
    final remaining = await dbService.getAllSongs();
    expect(remaining.length, equals(1));
    expect(remaining.first.title, equals('Midnight City'));
  });
}
