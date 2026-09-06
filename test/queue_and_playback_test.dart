import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicapp/core/audio/playback_state.dart';
import 'package:musicapp/core/library/song_model.dart';
import 'package:musicapp/features/playback/playback_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Queue and Playback Mode Tests', () {
    final song1 = Song(
      id: '1',
      title: 'Song One',
      artist: 'Artist A',
      album: 'Album X',
      duration: const Duration(seconds: 180),
      filePath: '/path/1.mp3',
    );
    final song2 = Song(
      id: '2',
      title: 'Song Two',
      artist: 'Artist B',
      album: 'Album X',
      duration: const Duration(seconds: 200),
      filePath: '/path/2.mp3',
    );
    final song3 = Song(
      id: '3',
      title: 'Song Three',
      artist: 'Artist C',
      album: 'Album Y',
      duration: const Duration(seconds: 220),
      filePath: '/path/3.mp3',
    );
    final song4 = Song(
      id: '4',
      title: 'Song Four',
      artist: 'Artist D',
      album: 'Album Z',
      duration: const Duration(seconds: 240),
      filePath: '/path/4.mp3',
    );

    test('PlaybackState upcomingSongs computes correctly', () {
      final state = PlaybackState(
        currentSong: song1,
        currentIndex: 0,
        playlist: [song1, song2, song3],
      );

      expect(state.upcomingSongs.length, equals(2));
      expect(state.upcomingSongs[0].id, equals('2'));
      expect(state.upcomingSongs[1].id, equals('3'));
    });

    test('PlaybackNotifier addToQueue appends to playlist', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(playbackNotifierProvider.notifier);

      notifier.addToQueue(song1);
      notifier.addToQueue(song2);

      final state = container.read(playbackNotifierProvider);
      expect(state.playlist.length, equals(2));
      expect(state.playlist[0].id, equals('1'));
      expect(state.playlist[1].id, equals('2'));
    });

    test('PlaybackNotifier playNextInQueue inserts immediately after current', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(playbackNotifierProvider.notifier);
      notifier.addToQueue(song1);
      notifier.addToQueue(song3);

      // Current index at 0 (song1)
      notifier.playNextInQueue(song2);

      final state = container.read(playbackNotifierProvider);
      expect(state.playlist.length, equals(3));
      expect(state.playlist[0].id, equals('1'));
      expect(state.playlist[1].id, equals('2'));
      expect(state.playlist[2].id, equals('3'));
    });

    test('PlaybackNotifier removeFromQueue removes upcoming song', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(playbackNotifierProvider.notifier);
      notifier.addToQueue(song1);
      notifier.addToQueue(song2);
      notifier.addToQueue(song3);

      // Remove upcoming item at index 0 (song2)
      notifier.removeFromQueue(0);

      final state = container.read(playbackNotifierProvider);
      expect(state.playlist.length, equals(2));
      expect(state.playlist[0].id, equals('1'));
      expect(state.playlist[1].id, equals('3'));
    });

    test('PlaybackNotifier clearQueue removes all upcoming songs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(playbackNotifierProvider.notifier);
      notifier.addToQueue(song1);
      notifier.addToQueue(song2);
      notifier.addToQueue(song3);

      notifier.clearQueue();

      final state = container.read(playbackNotifierProvider);
      // Only current and prior songs remain
      expect(state.playlist.length, equals(1));
      expect(state.playlist[0].id, equals('1'));
      expect(state.upcomingSongs.isEmpty, isTrue);
    });

    test('PlaybackNotifier cycleRepeatMode cycles through off -> all -> one -> off', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(playbackNotifierProvider.notifier);
      expect(container.read(playbackNotifierProvider).repeatMode, equals(AudioRepeatMode.off));

      notifier.cycleRepeatMode();
      expect(container.read(playbackNotifierProvider).repeatMode, equals(AudioRepeatMode.all));

      notifier.cycleRepeatMode();
      expect(container.read(playbackNotifierProvider).repeatMode, equals(AudioRepeatMode.one));

      notifier.cycleRepeatMode();
      expect(container.read(playbackNotifierProvider).repeatMode, equals(AudioRepeatMode.off));
    });

    test('PlaybackNotifier toggleShuffle enables and restores original playlist', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(playbackNotifierProvider.notifier);
      notifier.addToQueue(song1);
      notifier.addToQueue(song2);
      notifier.addToQueue(song3);
      notifier.addToQueue(song4);

      notifier.toggleShuffle();
      var state = container.read(playbackNotifierProvider);
      expect(state.isShuffled, isTrue);
      expect(state.playlist.length, equals(4));

      // Toggle off restores original
      notifier.toggleShuffle();
      state = container.read(playbackNotifierProvider);
      expect(state.isShuffled, isFalse);
      expect(state.playlist.map((s) => s.id).toList(), equals(['1', '2', '3', '4']));
    });
  });
}
