import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/lyrics/local_lyrics_finder.dart';
import '../../core/lyrics/lrc_parser.dart';
import '../../core/lyrics/lyric_line.dart';
import '../playback/playback_provider.dart';

@immutable
class LyricsState {
  final bool isLoading;
  final ParsedLyrics lyrics;
  final int activeLineIndex;
  final String? lyricsFilePath;
  final String? songId;

  const LyricsState({
    this.isLoading = false,
    this.lyrics = const ParsedLyrics.empty(),
    this.activeLineIndex = -1,
    this.lyricsFilePath,
    this.songId,
  });

  bool get hasLyrics => lyrics.isNotEmpty;
  bool get isSynced => lyrics.isSynced;

  LyricsState copyWith({
    bool? isLoading,
    ParsedLyrics? lyrics,
    int? activeLineIndex,
    String? lyricsFilePath,
    String? songId,
  }) {
    return LyricsState(
      isLoading: isLoading ?? this.isLoading,
      lyrics: lyrics ?? this.lyrics,
      activeLineIndex: activeLineIndex ?? this.activeLineIndex,
      lyricsFilePath: lyricsFilePath ?? this.lyricsFilePath,
      songId: songId ?? this.songId,
    );
  }
}

class LyricsNotifier extends Notifier<LyricsState> {
  String? _loadedSongId;

  @override
  LyricsState build() {
    // Listen for track changes to automatically load lyrics
    ref.listen(playbackNotifierProvider.select((s) => s.currentSong), (prev, current) {
      if (current == null) {
        _loadedSongId = null;
        state = const LyricsState();
      } else if (current.id != _loadedSongId) {
        _loadedSongId = current.id;
        loadLyricsForSong();
      }
    });

    // Listen for position ticks and update active line index only when line changes
    ref.listen(playbackNotifierProvider.select((s) => s.position), (prev, pos) {
      if (state.isSynced && state.lyrics.isNotEmpty) {
        final newIndex = state.lyrics.getActiveLineIndex(pos);
        if (newIndex != state.activeLineIndex) {
          state = state.copyWith(activeLineIndex: newIndex);
        }
      }
    });

    // Initialize with current song if already playing
    Future.microtask(() {
      final currentSong = ref.read(playbackNotifierProvider).currentSong;
      if (currentSong != null && currentSong.id != _loadedSongId) {
        _loadedSongId = currentSong.id;
        loadLyricsForSong();
      }
    });

    return const LyricsState();
  }

  Future<void> loadLyricsForSong() async {
    final song = ref.read(playbackNotifierProvider).currentSong;
    if (song == null) {
      state = const LyricsState();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      songId: song.id,
      activeLineIndex: -1,
    );

    try {
      final result = await LocalLyricsFinder.findLyricsForSong(song);
      if (result != null) {
        final parsed = LrcParser.parse(result.content);
        final currentPos = ref.read(playbackNotifierProvider).position;
        final initialIndex = parsed.getActiveLineIndex(currentPos);

        state = LyricsState(
          isLoading: false,
          lyrics: parsed,
          activeLineIndex: initialIndex,
          lyricsFilePath: result.filePath,
          songId: song.id,
        );
      } else {
        state = LyricsState(
          isLoading: false,
          lyrics: const ParsedLyrics.empty(),
          activeLineIndex: -1,
          lyricsFilePath: null,
          songId: song.id,
        );
      }
    } catch (_) {
      state = LyricsState(
        isLoading: false,
        lyrics: const ParsedLyrics.empty(),
        activeLineIndex: -1,
        lyricsFilePath: null,
        songId: song.id,
      );
    }
  }

  /// Jumps playback position to the timestamp of [index].
  Future<void> seekToLine(int index) async {
    if (index >= 0 && index < state.lyrics.lines.length) {
      final target = state.lyrics.lines[index].timestamp;
      await ref.read(playbackNotifierProvider.notifier).seek(target);
    }
  }
}

final lyricsNotifierProvider =
    NotifierProvider<LyricsNotifier, LyricsState>(LyricsNotifier.new);
