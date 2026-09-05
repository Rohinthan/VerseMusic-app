import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/audio/playback_state.dart';
import 'package:musicapp/core/library/song_model.dart';

void main() {
  group('PlaybackState Tests', () {
    const song1 = Song(
      id: 'id-1',
      filePath: '/music/song1.mp3',
      title: 'Song 1',
      artist: 'Artist 1',
      album: 'Album 1',
      duration: Duration(seconds: 200),
    );

    const song2 = Song(
      id: 'id-2',
      filePath: '/music/song2.mp3',
      title: 'Song 2',
      artist: 'Artist 2',
      album: 'Album 2',
      duration: Duration(seconds: 150),
    );

    test('initial state has default values', () {
      const state = PlaybackState();
      expect(state.currentSong, isNull);
      expect(state.currentIndex, -1);
      expect(state.status, PlayerStatus.idle);
      expect(state.isPlaying, isFalse);
      expect(state.hasCurrentSong, isFalse);
      expect(state.progress, 0.0);
    });

    test('progress calculation works proportionally', () {
      final state = const PlaybackState().copyWith(
        duration: const Duration(seconds: 100),
        position: const Duration(seconds: 25),
      );
      expect(state.progress, closeTo(0.25, 0.001));
    });

    test('progress clamps between 0.0 and 1.0', () {
      final stateOver = const PlaybackState().copyWith(
        duration: const Duration(seconds: 100),
        position: const Duration(seconds: 120),
      );
      expect(stateOver.progress, 1.0);
    });

    test('hasNext and hasPrevious operate correctly on playlist', () {
      final state = const PlaybackState().copyWith(
        playlist: [song1, song2],
        currentIndex: 0,
        currentSong: song1,
      );

      expect(state.hasNext, isTrue);
      expect(state.hasPrevious, isFalse);

      final nextState = state.copyWith(
        currentIndex: 1,
        currentSong: song2,
      );
      expect(nextState.hasNext, isFalse);
      expect(nextState.hasPrevious, isTrue);
    });
  });
}
