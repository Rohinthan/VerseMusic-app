import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:musicapp/core/library/song_model.dart';
import 'package:musicapp/core/lyrics/cached_lyrics_model.dart';
import 'package:musicapp/core/lyrics/local_lyrics_finder.dart';
import 'package:musicapp/core/lyrics/lrclib_client.dart';
import 'package:musicapp/core/lyrics/lyrics_repository.dart';
import 'package:musicapp/core/storage/database_service.dart';

class FakeDatabaseService extends DatabaseService {
  final Map<String, CachedLyricsRecord> storage = {};

  @override
  Future<CachedLyricsRecord?> getCachedLyrics(String songId) async {
    return storage[songId];
  }

  @override
  Future<void> saveCachedLyrics(CachedLyricsRecord record) async {
    storage[record.songId] = record;
  }

  @override
  Future<void> deleteCachedLyrics(String songId) async {
    storage.remove(songId);
  }

  @override
  Future<void> clearLyricsCache() async {
    storage.clear();
  }
}

void main() {
  final testSong = Song(
    id: 'test-song-1',
    filePath: '/music/song1.mp3',
    title: 'Midnight City',
    artist: 'M83',
    album: 'Hurry Up, We\'re Dreaming',
    duration: const Duration(seconds: 243),
  );

  group('LyricsRepository 3-Tier Resolution Tests', () {
    test('Tier 1: Returns local lyrics if .lrc file exists, skipping cache and API', () async {
      final fakeDb = FakeDatabaseService();
      var apiCalled = false;
      final mockHttp = MockClient((req) async {
        apiCalled = true;
        return http.Response('{"error": "Should not be called"}', 500);
      });
      final lrclib = LrclibClient(client: mockHttp);

      final repo = LyricsRepository(dbService: fakeDb, lrclibClient: lrclib);

      final result = await repo.getLyricsForSong(
        testSong,
        localFinderOverride: (song) async => const LocalLyricsResult(
          filePath: '/music/song1.lrc',
          content: '[00:01.00] Local synced lyric line',
        ),
      );

      expect(result, isNotNull);
      expect(result!.source, equals(LyricsSource.local));
      expect(result.lyrics.lines.first.text, equals('Local synced lyric line'));
      expect(result.filePath, equals('/music/song1.lrc'));
      expect(apiCalled, isFalse);
      expect(fakeDb.storage, isEmpty);
    });

    test('Tier 2: Returns cached lyrics if local misses, skipping API', () async {
      final fakeDb = FakeDatabaseService();
      fakeDb.storage[testSong.id] = CachedLyricsRecord(
        songId: testSong.id,
        syncedLyrics: '[00:02.00] Cached synced lyric line',
        isSynced: true,
        source: 'lrclib',
        fetchedAt: DateTime.now(),
      );

      var apiCalled = false;
      final mockHttp = MockClient((req) async {
        apiCalled = true;
        return http.Response('{"error": "Should not be called"}', 500);
      });
      final lrclib = LrclibClient(client: mockHttp);

      final repo = LyricsRepository(dbService: fakeDb, lrclibClient: lrclib);

      final result = await repo.getLyricsForSong(
        testSong,
        localFinderOverride: (song) async => null,
      );

      expect(result, isNotNull);
      expect(result!.source, equals(LyricsSource.cache));
      expect(result.lyrics.lines.first.text, equals('Cached synced lyric line'));
      expect(apiCalled, isFalse);
    });

    test('Tier 3: Fetches from LRCLIB when local and cache miss, persisting to cache', () async {
      final fakeDb = FakeDatabaseService();
      var apiCalls = 0;
      final mockHttp = MockClient((req) async {
        apiCalls++;
        return http.Response(
          jsonEncode({
            'id': 777,
            'trackName': 'Midnight City',
            'artistName': 'M83',
            'syncedLyrics': '[00:03.50] City is my church',
            'plainLyrics': 'City is my church',
          }),
          200,
        );
      });
      final lrclib = LrclibClient(client: mockHttp);

      final repo = LyricsRepository(dbService: fakeDb, lrclibClient: lrclib);

      final result = await repo.getLyricsForSong(
        testSong,
        localFinderOverride: (song) async => null,
      );

      expect(result, isNotNull);
      expect(result!.source, equals(LyricsSource.lrclib));
      expect(result.lyrics.lines.first.text, equals('City is my church'));
      expect(apiCalls, equals(1));

      // Verified saved to cache
      expect(fakeDb.storage.containsKey(testSong.id), isTrue);
      final cached = fakeDb.storage[testSong.id]!;
      expect(cached.syncedLyrics, contains('City is my church'));
      expect(cached.isSynced, isTrue);
    });

    test('Tier 3: Handles instrumental songs from LRCLIB correctly', () async {
      final fakeDb = FakeDatabaseService();
      final mockHttp = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'id': 888,
            'trackName': 'Midnight City',
            'artistName': 'M83',
            'instrumental': true,
          }),
          200,
        );
      });
      final lrclib = LrclibClient(client: mockHttp);

      final repo = LyricsRepository(dbService: fakeDb, lrclibClient: lrclib);

      final result = await repo.getLyricsForSong(
        testSong,
        localFinderOverride: (song) async => null,
      );

      expect(result, isNotNull);
      expect(result!.isInstrumental, isTrue);
      expect(result.hasLyrics, isFalse);
      expect(fakeDb.storage[testSong.id]!.isInstrumental, isTrue);
    });

    test('forceRefresh skips cache and fetches freshly from LRCLIB', () async {
      final fakeDb = FakeDatabaseService();
      fakeDb.storage[testSong.id] = CachedLyricsRecord(
        songId: testSong.id,
        syncedLyrics: '[00:01.00] Old cached lyric',
        isSynced: true,
        source: 'lrclib',
        fetchedAt: DateTime.now(),
      );

      final mockHttp = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'id': 999,
            'trackName': 'Midnight City',
            'artistName': 'M83',
            'syncedLyrics': '[00:01.00] Updated fresh lyric',
          }),
          200,
        );
      });
      final lrclib = LrclibClient(client: mockHttp);

      final repo = LyricsRepository(dbService: fakeDb, lrclibClient: lrclib);

      final result = await repo.getLyricsForSong(
        testSong,
        forceRefresh: true,
        localFinderOverride: (song) async => null,
      );

      expect(result, isNotNull);
      expect(result!.source, equals(LyricsSource.lrclib));
      expect(result.lyrics.lines.first.text, equals('Updated fresh lyric'));
      expect(fakeDb.storage[testSong.id]!.syncedLyrics, contains('Updated fresh lyric'));
    });
  });
}
