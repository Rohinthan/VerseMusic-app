import '../library/song_model.dart';

enum PlayerStatus {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

enum AudioRepeatMode {
  off,
  all,
  one,
}

class PlaybackState {
  final Song? currentSong;
  final int currentIndex;
  final PlayerStatus status;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final double volume;
  final String? errorMessage;
  final List<Song> playlist;
  final List<Song> originalPlaylist;
  final bool isShuffled;
  final AudioRepeatMode repeatMode;

  const PlaybackState({
    this.currentSong,
    this.currentIndex = -1,
    this.status = PlayerStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.volume = 1.0,
    this.errorMessage,
    this.playlist = const [],
    this.originalPlaylist = const [],
    this.isShuffled = false,
    this.repeatMode = AudioRepeatMode.off,
  });

  bool get isPlaying => status == PlayerStatus.playing;
  bool get isLoading => status == PlayerStatus.loading;
  bool get hasCurrentSong => currentSong != null;
  bool get hasNext => currentIndex >= 0 && currentIndex < playlist.length - 1;
  bool get hasPrevious => currentIndex > 0;

  List<Song> get upcomingSongs {
    if (currentIndex < 0 || currentIndex >= playlist.length - 1) {
      return const [];
    }
    return playlist.sublist(currentIndex + 1);
  }

  double get progress {
    if (duration.inMilliseconds <= 0) return 0.0;
    final val = position.inMilliseconds / duration.inMilliseconds;
    return val.clamp(0.0, 1.0);
  }

  PlaybackState copyWith({
    Song? currentSong,
    int? currentIndex,
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? volume,
    String? errorMessage,
    List<Song>? playlist,
    List<Song>? originalPlaylist,
    bool? isShuffled,
    AudioRepeatMode? repeatMode,
    bool clearSong = false,
  }) {
    return PlaybackState(
      currentSong: clearSong ? null : (currentSong ?? this.currentSong),
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      volume: volume ?? this.volume,
      errorMessage: errorMessage,
      playlist: playlist ?? this.playlist,
      originalPlaylist: originalPlaylist ?? this.originalPlaylist,
      isShuffled: isShuffled ?? this.isShuffled,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}
