import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:musicapp/core/lyrics/lrclib_client.dart';

void main() {
  group('LrclibClient Title & Artist Cleaning Tests', () {
    test('cleanTitle strips official video, audio, visualizer, remastered', () {
      expect(
        LrclibClient.cleanTitle('Midnight City (Official Video)'),
        equals('Midnight City'),
      );
      expect(
        LrclibClient.cleanTitle('Starboy [Official Music Video]'),
        equals('Starboy'),
      );
      expect(
        LrclibClient.cleanTitle('Comfortably Numb (Remastered 2011)'),
        equals('Comfortably Numb'),
      );
      expect(
        LrclibClient.cleanTitle('In The End (Official HD Video)'),
        equals('In The End'),
      );
      expect(
        LrclibClient.cleanTitle('Numb (256k)'),
        equals('Numb'),
      );
      expect(
        LrclibClient.cleanTitle('Something Just Like This (Lyric Video)'),
        equals('Something Just Like This'),
      );
      expect(
        LrclibClient.cleanTitle('Stay (Visualizer)'),
        equals('Stay'),
      );
    });

    test('cleanTitle strips featured artist annotations', () {
      expect(
        LrclibClient.cleanTitle('God\'s Country (feat. Travis Scott)'),
        equals('God\'s Country'),
      );
      expect(
        LrclibClient.cleanTitle('Industry Baby [ft. Jack Harlow]'),
        equals('Industry Baby'),
      );
      expect(
        LrclibClient.cleanTitle('Ghost feat. Justin Bieber'),
        equals('Ghost'),
      );
    });

    test('cleanArtist extracts primary artist', () {
      expect(
        LrclibClient.cleanArtist('The Weeknd feat. Daft Punk'),
        equals('The Weeknd'),
      );
      expect(
        LrclibClient.cleanArtist('Lil Nas X ft. Jack Harlow'),
        equals('Lil Nas X'),
      );
      expect(
        LrclibClient.cleanArtist('Radiohead  '),
        equals('Radiohead'),
      );
    });
  });

  group('LrclibClient API Tests', () {
    test('fetchLyrics returns exact match when /api/get succeeds', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/get') {
          expect(request.url.queryParameters['track_name'], equals('Midnight City'));
          expect(request.url.queryParameters['artist_name'], equals('M83'));
          return http.Response(
            jsonEncode({
              'id': 1001,
              'name': 'Midnight City',
              'trackName': 'Midnight City',
              'artistName': 'M83',
              'albumName': 'Hurry Up, We\'re Dreaming',
              'duration': 243.0,
              'instrumental': false,
              'plainLyrics': 'Waiting in a car...',
              'syncedLyrics': '[00:05.10] Waiting in a car...',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error": "Not Found"}', 404);
      });

      final client = LrclibClient(client: mockClient);
      final res = await client.fetchLyrics(
        trackName: 'Midnight City',
        artistName: 'M83',
      );

      expect(res, isNotNull);
      expect(res!.id, equals(1001));
      expect(res.trackName, equals('Midnight City'));
      expect(res.isSynced, isTrue);
      expect(res.syncedLyrics, contains('[00:05.10]'));
      expect(res.plainLyrics, equals('Waiting in a car...'));
      expect(res.instrumental, isFalse);
    });

    test('fetchLyrics retries with cleaned title if first exact fails', () async {
      final requestedUrls = <String>[];
      final mockClient = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        if (request.url.path == '/api/get') {
          if (request.url.queryParameters['track_name'] == 'Midnight City (Official Video)') {
            return http.Response('{"error": "Not Found"}', 404);
          }
          if (request.url.queryParameters['track_name'] == 'Midnight City') {
            return http.Response(
              jsonEncode({
                'id': 1002,
                'trackName': 'Midnight City',
                'artistName': 'M83',
                'instrumental': false,
                'syncedLyrics': '[00:01.00] Synced line',
              }),
              200,
            );
          }
        }
        return http.Response('{"error": "Not Found"}', 404);
      });

      final client = LrclibClient(client: mockClient);
      final res = await client.fetchLyrics(
        trackName: 'Midnight City (Official Video)',
        artistName: 'M83',
      );

      expect(res, isNotNull);
      expect(res!.id, equals(1002));
      expect(requestedUrls.length, greaterThanOrEqualTo(2));
    });

    test('fetchLyrics falls back to /api/search if /api/get fails', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/get') {
          return http.Response('{"error": "Not Found"}', 404);
        }
        if (request.url.path == '/api/search') {
          return http.Response(
            jsonEncode([
              {
                'id': 2001,
                'trackName': 'Clair de Lune',
                'artistName': 'Claude Debussy',
                'duration': 300.0,
                'instrumental': true,
              }
            ]),
            200,
          );
        }
        return http.Response('{"error": "Not Found"}', 404);
      });

      final client = LrclibClient(client: mockClient);
      final res = await client.fetchLyrics(
        trackName: 'Clair de Lune',
        artistName: 'Debussy',
      );

      expect(res, isNotNull);
      expect(res!.id, equals(2001));
      expect(res.instrumental, isTrue);
    });

    test('fetchLyrics returns null gracefully on 404 not found or empty search', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/get') {
          return http.Response('{"error": "Not Found"}', 404);
        }
        if (request.url.path == '/api/search') {
          return http.Response('[]', 200);
        }
        return http.Response('{"error": "Not Found"}', 404);
      });

      final client = LrclibClient(client: mockClient);
      final res = await client.fetchLyrics(
        trackName: 'NonExistentSong12345',
        artistName: 'UnknownArtist99999',
      );

      expect(res, isNull);
    });
  });
}
