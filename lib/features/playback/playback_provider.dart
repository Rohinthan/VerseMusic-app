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
          // Auto advance to next track on completion
          playNext();
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

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    final list = playlist ?? state.playlist;
    final index = list.indexWhere((s) => s.id == song.id);

    state = state.copyWith(
      currentSong: song,
      currentIndex: index >= 0 ? index : 0,
      playlist: list.isNotEmpty ? list : [song],
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

    final nextIndex = state.currentIndex + 1;
    if (nextIndex < state.playlist.length) {
      await playSong(state.playlist[nextIndex]);
    } else {
      // Loop back to start or stop
      await playSong(state.playlist[0]);
    }
  }

  Future<void> playPrevious() async {
    if (state.playlist.isEmpty) return;

    // If current song has played for more than 3 seconds, rewind to start
    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    final prevIndex = state.currentIndex - 1;
    if (prevIndex >= 0) {
      await playSong(state.playlist[prevIndex]);
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
}

final playbackNotifierProvider =
    NotifierProvider<PlaybackNotifier, PlaybackState>(PlaybackNotifier.new);
