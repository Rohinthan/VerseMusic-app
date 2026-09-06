import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../library/song_model.dart';

/// Bridges the player to Android's MediaSession & Lockscreen notifications.
class VerseAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;
  void Function()? onSkipToNext;
  void Function()? onSkipToPrevious;
  void Function(int)? onSetRepeatMode;
  void Function(bool)? onSetShuffleMode;

  VerseAudioHandler(this._player) {
    _initStreams();
  }

  void updateCurrentSong(Song? song) {
    if (song == null) {
      mediaItem.add(null);
      return;
    }

    mediaItem.add(
      MediaItem(
        id: song.id,
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: song.duration,
        artUri: song.artPath != null ? Uri.file(song.artPath!) : null,
      ),
    );
  }

  void _initStreams() {
    _player.playbackEventStream.listen((event) {
      final isPlaying = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (isPlaying) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState] ?? AudioProcessingState.idle,
          playing: isPlaying,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        ),
      );
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> skipToNext() async {
    onSkipToNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onSkipToPrevious?.call();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    onSetRepeatMode?.call(repeatMode.index);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    onSetShuffleMode?.call(shuffleMode != AudioServiceShuffleMode.none);
  }
}
