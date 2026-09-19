import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:musicapp/core/audio/audio_player_service.dart';
import 'package:musicapp/core/library/song_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isLinux) {
      JustAudioMediaKit.ensureInitialized(
        linux: true,
        windows: false,
        android: false,
        iOS: false,
        macOS: false,
      );
    }
  });

  test('AudioPlayerService initializes and loads a real song without error', () async {
    final musicDir = Directory('/home/raccoon/Music/musics');
    if (!await musicDir.exists()) return;

    final files = musicDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.mp3'));
    if (files.isEmpty) return;

    final firstFile = files.first;
    final song = Song(
      id: Song.generateId(firstFile.path),
      filePath: firstFile.path,
      title: 'Test Song',
      artist: 'Test Artist',
      album: 'Test Album',
      duration: const Duration(seconds: 180),
    );

    final service = AudioPlayerService();
    try {
      final duration = await service.playSong(song);
      expect(duration, isNotNull);
      expect(duration!.inSeconds, greaterThan(0));

      await service.pause();
      expect(service.isPlaying, isFalse);

      await service.seek(const Duration(seconds: 5));
      expect(service.currentPosition.inSeconds, equals(5));
    } finally {
      await service.dispose();
    }
  });

  test('AudioPlayerService transitions seamlessly between consecutive songs', () async {
    final musicDir = Directory('/home/raccoon/Music/musics');
    if (!await musicDir.exists()) return;

    final files = musicDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.mp3'))
        .take(2)
        .toList();
    if (files.length < 2) return;

    final song1 = Song(
      id: Song.generateId(files[0].path),
      filePath: files[0].path,
      title: 'Test Song 1',
      artist: 'Test Artist 1',
      album: 'Test Album 1',
      duration: const Duration(seconds: 180),
    );

    final song2 = Song(
      id: Song.generateId(files[1].path),
      filePath: files[1].path,
      title: 'Test Song 2',
      artist: 'Test Artist 2',
      album: 'Test Album 2',
      duration: const Duration(seconds: 180),
    );

    final service = AudioPlayerService();
    try {
      final dur1 = await service.playSong(song1);
      expect(dur1, isNotNull);
      expect(service.isPlaying, isTrue);

      // Transition immediately to song 2
      final dur2 = await service.playSong(song2);
      expect(dur2, isNotNull);
      expect(service.isPlaying, isTrue);
    } finally {
      await service.dispose();
    }
  });
}
