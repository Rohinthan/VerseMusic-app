import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/audio/audio_player_service.dart';
import '../../core/audio/playback_state.dart';
import '../../core/library/song_model.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

class PlaybackNotifier extends Notifier<PlaybackState> {
  late final AudioPlayerService _audioService;
  final List<StreamSubscription> _subscriptions = [];

  @override
  PlaybackState build() {
    _audioService = ref.read(audioPlayerServiceProvider);
    _initListeners();

    // Initialize platform background media controls & notification on Android
    Future.microtask(() {
      _audioService.initializeBackgroundService(
        onNext: () => playNext(),
        onPrevious: () => playPrevious(),
        onRepeatMode: (mode) =>
            setRepeatMode(AudioRepeatMode.values[mode % AudioRepeatMode.values.length]),
        onShuffleMode: (shuffled) => setShuffle(shuffled),
      );
    });

    ref.onDispose(() {
      for (final sub in _subscriptions) {
        sub.cancel();
      }
      _subscriptions.clear();
    });

    return const PlaybackState();
  }

  void _initListeners() {
    // Player state stream (playing / buffering / completed)
    _subscriptions.add(
      _audioService.playerStateStream.listen((playerState) {
        final processingState = playerState.processingState;
        final isPlaying = playerState.playing;

        PlayerStatus status;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          status = PlayerStatus.loading;
        } else if (processingState == ProcessingState.completed) {
          status = PlayerStatus.completed;
          _handleTrackCompletion();
          return;
        } else if (isPlaying) {
          status = PlayerStatus.playing;
        } else {
          status = PlayerStatus.paused;
        }

        state = state.copyWith(status: status);
      }),
    );

    // Position stream
    _subscriptions.add(
      _audioService.positionStream.listen((position) {
        state = state.copyWith(position: position);
      }),
    );

    // Duration stream
    _subscriptions.add(
      _audioService.durationStream.listen((duration) {
        if (duration != null && duration != Duration.zero) {
          state = state.copyWith(duration: duration);
        }
      }),
    );

    // Buffered position stream
    _subscriptions.add(
      _audioService.bufferedPositionStream.listen((buffered) {
        state = state.copyWith(bufferedPosition: buffered);
      }),
    );
  }

  Future<void> _handleTrackCompletion() async {
    if (state.repeatMode == AudioRepeatMode.one) {
      await seek(Duration.zero);
      await _audioService.play();
      return;
    }

    if (state.hasNext) {
      await playSong(state.playlist[state.currentIndex + 1]);
    } else if (state.repeatMode == AudioRepeatMode.all && state.playlist.isNotEmpty) {
      await playSong(state.playlist[0]);
    } else {
      // Reached end of playlist with AudioRepeatMode.off
      state = state.copyWith(status: PlayerStatus.paused);
      await seek(Duration.zero);
    }
  }

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    final list = playlist ?? state.playlist;
    final index = list.indexWhere((s) => s.id == song.id);

    final isNewPlaylist = playlist != null;

    state = state.copyWith(
      currentSong: song,
      currentIndex: index >= 0 ? index : 0,
      playlist: list.isNotEmpty ? list : [song],
      originalPlaylist: isNewPlaylist
          ? (list.isNotEmpty ? list : [song])
          : (state.originalPlaylist.isNotEmpty
              ? state.originalPlaylist
              : (list.isNotEmpty ? list : [song])),
      status: PlayerStatus.loading,
      position: Duration.zero,
      duration: song.duration,
      errorMessage: null,
    );

    try {
      final detectedDuration = await _audioService.playSong(song);
      if (detectedDuration != null && detectedDuration != Duration.zero) {
        state = state.copyWith(duration: detectedDuration);
      }
    } catch (e) {
      state = state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Playback error: $e',
      );
    }
  }

  Future<void> togglePlayPause() async {
    if (!state.hasCurrentSong) return;

    if (state.isPlaying) {
      await _audioService.pause();
    } else {
      await _audioService.play();
    }
  }

  Future<void> playNext() async {
    if (state.playlist.isEmpty) return;

    if (state.repeatMode == AudioRepeatMode.one) {
      await seek(Duration.zero);
      await _audioService.play();
      return;
    }

    final nextIndex = state.currentIndex + 1;
    if (nextIndex < state.playlist.length) {
      await playSong(state.playlist[nextIndex]);
    } else if (state.repeatMode == AudioRepeatMode.all) {
      await playSong(state.playlist[0]);
    } else {
      // End reached
      await seek(Duration.zero);
      await _audioService.pause();
    }
  }

  Future<void> playPrevious() async {
    if (state.playlist.isEmpty) return;

    // If current song has played for more than 3 seconds, restart it
    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    final prevIndex = state.currentIndex - 1;
    if (prevIndex >= 0) {
      await playSong(state.playlist[prevIndex]);
    } else if (state.repeatMode == AudioRepeatMode.all) {
      await playSong(state.playlist[state.playlist.length - 1]);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> setVolume(double volume) async {
    state = state.copyWith(volume: volume);
    await _audioService.setVolume(volume);
  }

  // Shuffle Controls
  void toggleShuffle() {
    if (!state.isShuffled) {
      // Enable shuffle: preserve current song, shuffle the upcoming sequence
      if (state.playlist.isEmpty) return;

      final original = state.originalPlaylist.isNotEmpty
          ? state.originalPlaylist
          : List<Song>.from(state.playlist);

      if (state.currentIndex < 0 || state.currentSong == null) {
        final shuffled = List<Song>.from(state.playlist)..shuffle();
        state = state.copyWith(
          playlist: shuffled,
          originalPlaylist: original,
          isShuffled: true,
        );
        return;
      }

      final current = state.currentSong;
      final before = state.playlist.sublist(0, state.currentIndex);
      final after = state.playlist.sublist(state.currentIndex + 1);
      after.shuffle();

      final shuffledPlaylist = [
        ...before,
        ?current,
        ...after,
      ];

      state = state.copyWith(
        playlist: shuffledPlaylist,
        originalPlaylist: original,
        isShuffled: true,
      );
    } else {
      // Disable shuffle: restore original order
      if (state.originalPlaylist.isEmpty) {
        state = state.copyWith(isShuffled: false);
        return;
      }

      final currentId = state.currentSong?.id;
      final restored = List<Song>.from(state.originalPlaylist);
      final newIndex = currentId != null
          ? restored.indexWhere((s) => s.id == currentId)
          : 0;

      state = state.copyWith(
        playlist: restored,
        currentIndex: newIndex >= 0 ? newIndex : 0,
        isShuffled: false,
      );
    }
  }

  void setShuffle(bool enable) {
    if (state.isShuffled != enable) {
      toggleShuffle();
    }
  }

  // Repeat Controls
  void cycleRepeatMode() {
    switch (state.repeatMode) {
      case AudioRepeatMode.off:
        state = state.copyWith(repeatMode: AudioRepeatMode.all);
        break;
      case AudioRepeatMode.all:
        state = state.copyWith(repeatMode: AudioRepeatMode.one);
        break;
      case AudioRepeatMode.one:
        state = state.copyWith(repeatMode: AudioRepeatMode.off);
        break;
    }
  }

  void setRepeatMode(AudioRepeatMode mode) {
    state = state.copyWith(repeatMode: mode);
  }

  // Up-Next Queue Operations
  void addToQueue(Song song) {
    final list = List<Song>.from(state.playlist)..add(song);
    final isFirst = state.currentSong == null && state.playlist.isEmpty;
    state = state.copyWith(
      playlist: list,
      currentSong: isFirst ? song : state.currentSong,
      currentIndex: isFirst ? 0 : state.currentIndex,
    );
  }

  void playNextInQueue(Song song) {
    final list = List<Song>.from(state.playlist);
    final insertIdx = (state.currentIndex + 1).clamp(0, list.length);
    list.insert(insertIdx, song);
    state = state.copyWith(playlist: list);
  }

  void reorderQueue(int oldUpcomingIndex, int newUpcomingIndex) {
    final startIndex = state.currentIndex + 1;
    final actualOld = startIndex + oldUpcomingIndex;
    var actualNew = startIndex + newUpcomingIndex;

    if (actualOld < actualNew) {
      actualNew -= 1;
    }

    if (actualOld >= 0 &&
        actualOld < state.playlist.length &&
        actualNew >= 0 &&
        actualNew < state.playlist.length) {
      final list = List<Song>.from(state.playlist);
      final item = list.removeAt(actualOld);
      list.insert(actualNew, item);
      state = state.copyWith(playlist: list);
    }
  }

  void removeFromQueue(int upcomingIndex) {
    final actualIndex = state.currentIndex + 1 + upcomingIndex;
    if (actualIndex >= 0 && actualIndex < state.playlist.length) {
      final list = List<Song>.from(state.playlist)..removeAt(actualIndex);
      state = state.copyWith(playlist: list);
    }
  }

  void clearQueue() {
    if (state.currentIndex >= 0 && state.currentIndex < state.playlist.length) {
      final list = state.playlist.sublist(0, state.currentIndex + 1);
      state = state.copyWith(playlist: list);
    } else {
      state = state.copyWith(playlist: []);
    }
  }

  Future<void> jumpToQueueItem(int upcomingIndex) async {
    final targetIndex = state.currentIndex + 1 + upcomingIndex;
    if (targetIndex >= 0 && targetIndex < state.playlist.length) {
      await playSong(state.playlist[targetIndex]);
    }
  }
}

final playbackNotifierProvider =
    NotifierProvider<PlaybackNotifier, PlaybackState>(PlaybackNotifier.new);
