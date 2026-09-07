import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/lyrics/lyric_line.dart';
import '../../core/lyrics/lyrics_repository.dart';
import '../playback/playback_provider.dart';
import '../settings/settings_provider.dart';

final lyricsRepositoryProvider =
    Provider<LyricsRepository>((ref) => LyricsRepository());

@immutable
class LyricsState {
  final bool isLoading;
  final ParsedLyrics lyrics;
  final int activeLineIndex;
  final String? lyricsFilePath;
  final String? songId;
  final bool isInstrumental;
  final LyricsSource? source;

  const LyricsState({
    this.isLoading = false,
    this.lyrics = const ParsedLyrics.empty(),
    this.activeLineIndex = -1,
    this.lyricsFilePath,
    this.songId,
    this.isInstrumental = false,
    this.source,
  });

  bool get hasLyrics => lyrics.isNotEmpty;
  bool get isSynced => lyrics.isSynced;
  bool get isPlainText => lyrics.isNotEmpty && !lyrics.isSynced;

  String get sourceLabel {
    if (isInstrumental) return 'Instrumental';
    switch (source) {
      case LyricsSource.local:
        return 'Local .lrc file';
      case LyricsSource.cache:
        return 'Offline cache';
      case LyricsSource.lrclib:
        return 'Synced via LRCLIB';
      case null:
        return '';
    }
  }

  LyricsState copyWith({
    bool? isLoading,
    ParsedLyrics? lyrics,
    int? activeLineIndex,
    String? lyricsFilePath,
    String? songId,
    bool? isInstrumental,
    LyricsSource? source,
  }) {
    return LyricsState(
      isLoading: isLoading ?? this.isLoading,
      lyrics: lyrics ?? this.lyrics,
      activeLineIndex: activeLineIndex ?? this.activeLineIndex,
      lyricsFilePath: lyricsFilePath ?? this.lyricsFilePath,
      songId: songId ?? this.songId,
      isInstrumental: isInstrumental ?? this.isInstrumental,
      source: source ?? this.source,
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

  Future<void> loadLyricsForSong({bool forceRefresh = false}) async {
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
      final repo = ref.read(lyricsRepositoryProvider);
      final isOnlineEnabled = ref.read(lyricsOnlineFetchProvider);
      final result = await repo.getLyricsForSong(
        song,
        forceRefresh: forceRefresh,
        onlineFetchEnabled: isOnlineEnabled,
      );

      if (result != null) {
        final currentPos = ref.read(playbackNotifierProvider).position;
        final initialIndex = result.lyrics.isSynced
            ? result.lyrics.getActiveLineIndex(currentPos)
            : -1;

        state = LyricsState(
          isLoading: false,
          lyrics: result.lyrics,
          activeLineIndex: initialIndex,
          lyricsFilePath: result.filePath,
          songId: song.id,
          isInstrumental: result.isInstrumental,
          source: result.source,
        );
      } else {
        state = LyricsState(
          isLoading: false,
          lyrics: const ParsedLyrics.empty(),
          activeLineIndex: -1,
          lyricsFilePath: null,
          songId: song.id,
          isInstrumental: false,
          source: null,
        );
      }
    } catch (_) {
      state = LyricsState(
        isLoading: false,
        lyrics: const ParsedLyrics.empty(),
        activeLineIndex: -1,
        lyricsFilePath: null,
        songId: song.id,
        isInstrumental: false,
        source: null,
      );
    }
  }

  /// Forces an online re-fetch from LRCLIB bypassing the offline cache.
  Future<void> refresh() async {
    await loadLyricsForSong(forceRefresh: true);
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
