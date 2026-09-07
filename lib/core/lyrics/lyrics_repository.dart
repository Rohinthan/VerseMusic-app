import 'dart:async';
import 'package:flutter/foundation.dart';
import '../library/song_model.dart';
import '../storage/database_service.dart';
import 'cached_lyrics_model.dart';
import 'local_lyrics_finder.dart';
import 'lrc_parser.dart';
import 'lrclib_client.dart';
import 'lyric_line.dart';

enum LyricsSource {
  local,
  cache,
  lrclib,
}

@immutable
class LyricsResult {
  final ParsedLyrics lyrics;
  final LyricsSource source;
  final bool isInstrumental;
  final String? filePath;

  const LyricsResult({
    required this.lyrics,
    required this.source,
    this.isInstrumental = false,
    this.filePath,
  });

  bool get hasLyrics => lyrics.isNotEmpty;
  bool get isSynced => lyrics.isSynced;

  const LyricsResult.empty({this.source = LyricsSource.local})
      : lyrics = const ParsedLyrics.empty(),
        isInstrumental = false,
        filePath = null;
}

/// Repository coordinating 3-tier lyrics resolution:
/// 1. Local .lrc file
/// 2. SQLite cache
/// 3. LRCLIB online API fetch
class LyricsRepository {
  final DatabaseService _dbService;
  final LrclibClient _lrclibClient;

  LyricsRepository({
    DatabaseService? dbService,
    LrclibClient? lrclibClient,
  })  : _dbService = dbService ?? DatabaseService(),
        _lrclibClient = lrclibClient ?? LrclibClient();

  /// Gets lyrics for [song], checking Local -> Cache -> LRCLIB in order.
  Future<LyricsResult?> getLyricsForSong(
    Song song, {
    bool forceRefresh = false,
    bool onlineFetchEnabled = true,
    Future<LocalLyricsResult?> Function(Song song)? localFinderOverride,
  }) async {
    // 1. Tier 1: Local .lrc file check
    final localResult = localFinderOverride != null
        ? await localFinderOverride(song)
        : await LocalLyricsFinder.findLyricsForSong(song);

    if (localResult != null) {
      final parsed = LrcParser.parse(localResult.content);
      if (parsed.isNotEmpty) {
        return LyricsResult(
          lyrics: parsed,
          source: LyricsSource.local,
          filePath: localResult.filePath,
        );
      }
    }

    // 2. Tier 2: Persistent SQLite Cache check (unless forceRefresh is true)
    if (!forceRefresh) {
      try {
        final cached = await _dbService.getCachedLyrics(song.id);
        if (cached != null) {
          if (cached.isInstrumental) {
            return const LyricsResult(
              lyrics: ParsedLyrics.empty(),
              source: LyricsSource.cache,
              isInstrumental: true,
            );
          }

          final raw = cached.syncedLyrics ?? cached.plainLyrics;
          if (raw != null && raw.trim().isNotEmpty) {
            final parsed = LrcParser.parse(raw);
            return LyricsResult(
              lyrics: parsed,
              source: LyricsSource.cache,
              isInstrumental: false,
            );
          }
        }
      } catch (e) {
        debugPrint('[LyricsRepository] Cache read error: $e');
      }
    }

    // 3. Tier 3: LRCLIB API Fetch
    if (!onlineFetchEnabled) {
      return null;
    }

    try {
      final response = await _lrclibClient.fetchLyrics(
        trackName: song.title,
        artistName: song.artist,
        albumName: song.album.isEmpty ? null : song.album,
        duration: song.duration,
      );

      if (response != null) {
        if (response.instrumental) {
          final record = CachedLyricsRecord(
            songId: song.id,
            plainLyrics: null,
            syncedLyrics: null,
            isSynced: false,
            isInstrumental: true,
            source: 'lrclib',
            fetchedAt: DateTime.now(),
          );
          await _dbService.saveCachedLyrics(record);

          return const LyricsResult(
            lyrics: ParsedLyrics.empty(),
            source: LyricsSource.lrclib,
            isInstrumental: true,
          );
        }

        if (response.hasLyrics) {
          final raw = response.syncedLyrics ?? response.plainLyrics ?? '';
          final parsed = LrcParser.parse(raw);

          final record = CachedLyricsRecord(
            songId: song.id,
            plainLyrics: response.plainLyrics,
            syncedLyrics: response.syncedLyrics,
            isSynced: response.isSynced,
            isInstrumental: false,
            source: 'lrclib',
            fetchedAt: DateTime.now(),
          );
          await _dbService.saveCachedLyrics(record);

          return LyricsResult(
            lyrics: parsed,
            source: LyricsSource.lrclib,
            isInstrumental: false,
          );
        }
      }
    } catch (e) {
      debugPrint('[LyricsRepository] API fetch error: $e');
    }

    return null;
  }
}
