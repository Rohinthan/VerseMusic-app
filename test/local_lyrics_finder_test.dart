import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/library/song_model.dart';
import 'package:musicapp/core/lyrics/local_lyrics_finder.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lyrics_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('finds sibling .lrc file matching song audio file name', () async {
    final audioFile = File('${tempDir.path}/test_song.mp3');
    await audioFile.writeAsString('dummy mp3 content');

    final lrcFile = File('${tempDir.path}/test_song.lrc');
    await lrcFile.writeAsString('[00:05.00]Hello world synced lyrics');

    final song = Song(
      id: 'test_id',
      filePath: audioFile.path,
      title: 'Test Song',
      artist: 'Artist',
      album: 'Album',
      duration: const Duration(seconds: 120),
    );

    final result = await LocalLyricsFinder.findLyricsForSong(song);
    expect(result, isNotNull);
    expect(result!.filePath, equals(lrcFile.path));
    expect(result.content, contains('Hello world synced lyrics'));
  });

  test('finds .lrc file in lyrics subfolder', () async {
    final audioFile = File('${tempDir.path}/track_sub.flac');
    await audioFile.writeAsString('dummy flac');

    final subDir = Directory('${tempDir.path}/lyrics');
    await subDir.create(recursive: true);

    final lrcFile = File('${subDir.path}/track_sub.lrc');
    await lrcFile.writeAsString('[00:02.50]Lyrics from subfolder');

    final song = Song(
      id: 'sub_id',
      filePath: audioFile.path,
      title: 'Track Sub',
      artist: 'Artist',
      album: 'Album',
      duration: const Duration(seconds: 180),
    );

    final result = await LocalLyricsFinder.findLyricsForSong(song);
    expect(result, isNotNull);
    expect(result!.content, contains('Lyrics from subfolder'));
  });

  test('returns null when no matching lyrics file exists', () async {
    final audioFile = File('${tempDir.path}/no_lyrics.mp3');
    await audioFile.writeAsString('audio');

    final song = Song(
      id: 'none_id',
      filePath: audioFile.path,
      title: 'No Lyrics',
      artist: 'Artist',
      album: 'Album',
      duration: const Duration(seconds: 100),
    );

    final result = await LocalLyricsFinder.findLyricsForSong(song);
    expect(result, isNull);
  });
}
