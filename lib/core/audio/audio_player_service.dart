import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import '../library/song_model.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<double> get volumeStream => _player.volumeStream;

  Duration get currentPosition => _player.position;
  Duration? get currentDuration => _player.duration;
  bool get isPlaying => _player.playing;

  Future<Duration?> playSong(Song song) async {
    try {
      final file = File(song.filePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found at ${song.filePath}');
      }

      // Stop any current playback before loading new source
      await _player.stop();

      // Load file into player
      final duration = await _player.setFilePath(song.filePath);

      // Begin playback
      await _player.play();
      return duration;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
