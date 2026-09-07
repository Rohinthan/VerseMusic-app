import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Data class representing a lyrics result from LRCLIB.
@immutable
class LrclibResponse {
  final int id;
  final String trackName;
  final String artistName;
  final String? albumName;
  final double? duration;
  final bool instrumental;
  final String? plainLyrics;
  final String? syncedLyrics;

  const LrclibResponse({
    required this.id,
    required this.trackName,
    required this.artistName,
    this.albumName,
    this.duration,
    this.instrumental = false,
    this.plainLyrics,
    this.syncedLyrics,
  });

  bool get hasLyrics =>
      (syncedLyrics != null && syncedLyrics!.trim().isNotEmpty) ||
      (plainLyrics != null && plainLyrics!.trim().isNotEmpty);

  bool get isSynced => syncedLyrics != null && syncedLyrics!.trim().isNotEmpty;

  factory LrclibResponse.fromJson(Map<String, dynamic> json) {
    return LrclibResponse(
      id: json['id'] as int? ?? 0,
      trackName: (json['trackName'] ?? json['name'] ?? '') as String,
      artistName: (json['artistName'] ?? '') as String,
      albumName: json['albumName'] as String?,
      duration: (json['duration'] is num)
          ? (json['duration'] as num).toDouble()
          : null,
      instrumental: json['instrumental'] as bool? ?? false,
      plainLyrics: json['plainLyrics'] as String?,
      syncedLyrics: json['syncedLyrics'] as String?,
    );
  }
}

/// HTTP client for interacting with the LRCLIB (https://lrclib.net) API.
class LrclibClient {
  static const String baseUrl = 'https://lrclib.net/api';
  static const String userAgent =
      'VerseMusic/1.0.0 (https://github.com/Rohinthan/VerseMusic-app)';

  final http.Client _client;
  final Duration timeout;

  LrclibClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 6),
  }) : _client = client ?? http.Client();

  /// Cleans titles of common noise like "(Official Music Video)", "(Lyrics)", "(256k)", "(feat. X)"
  static String cleanTitle(String rawTitle) {
    var title = rawTitle.trim();

    // Remove text like: (Official Video), [Official Audio], (Lyric Video), (Visualizer), (Remastered 2011), (Official HD Video), (256k), etc.
    final noiseRegex = RegExp(
      r'\s*[\(\[](?:[^\)\]]*(?:official|lyrics?|visualizer|remaster|audio|video|hd|4k|\d+k)[^\)\]]*)[\)\]]',
      caseSensitive: false,
    );
    title = title.replaceAll(noiseRegex, '');

    // Remove featured artists: (feat. X) or [ft. X]
    final featRegex = RegExp(
      r'\s*[\(\[](?:feat\.|ft\.|featuring)\s+[^\)\]]+[\)\]]',
      caseSensitive: false,
    );
    title = title.replaceAll(featRegex, '');

    // Remove inline feat: " feat. Someone"
    final inlineFeat = RegExp(
      r'\s+(?:feat\.|ft\.|featuring)\s+.*$',
      caseSensitive: false,
    );
    title = title.replaceAll(inlineFeat, '');

    // Normalize multiple whitespace
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    return title.isEmpty ? rawTitle.trim() : title;
  }

  /// Cleans artist names (e.g. removes trailing separators, extra whitespace)
  static String cleanArtist(String rawArtist) {
    var artist = rawArtist.trim();
    // In multi-artist strings (e.g. "Artist A, Artist B" or "Artist A feat. B"), take primary artist
    if (artist.contains(' feat. ')) {
      artist = artist.split(' feat. ').first;
    } else if (artist.contains(' ft. ')) {
      artist = artist.split(' ft. ').first;
    }
    return artist.trim();
  }

  /// Attempts to fetch lyrics using `/api/get`.
  /// If 404 or no lyrics found, automatically retries with cleaned metadata,
  /// and finally falls back to `/api/search`.
  Future<LrclibResponse?> fetchLyrics({
    required String trackName,
    required String artistName,
    String? albumName,
    Duration? duration,
  }) async {
    final cleanT = cleanTitle(trackName);
    final cleanA = cleanArtist(artistName);

    // 1. First attempt: exact match with original metadata
    LrclibResponse? result = await _getExact(
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      duration: duration,
    );

    if (result != null && (result.hasLyrics || result.instrumental)) {
      return result;
    }

    // 2. Second attempt: exact match with cleaned title & artist
    if (cleanT != trackName || cleanA != artistName) {
      result = await _getExact(
        trackName: cleanT,
        artistName: cleanA,
        duration: duration,
      );

      if (result != null && (result.hasLyrics || result.instrumental)) {
        return result;
      }
    }

    // 3. Fallback: Search endpoint
    result = await _searchBest(
      trackName: cleanT,
      artistName: cleanA,
      duration: duration,
    );

    return result;
  }

  /// Exact lookup via `/api/get`
  Future<LrclibResponse?> _getExact({
    required String trackName,
    required String artistName,
    String? albumName,
    Duration? duration,
  }) async {
    try {
      final queryParams = <String, String>{
        'track_name': trackName,
        'artist_name': artistName,
      };

      if (albumName != null && albumName.trim().isNotEmpty) {
        queryParams['album_name'] = albumName.trim();
      }
      if (duration != null && duration.inSeconds > 0) {
        queryParams['duration'] = duration.inSeconds.toString();
      }

      final uri = Uri.parse('$baseUrl/get').replace(queryParameters: queryParams);
      final response = await _client.get(
        uri,
        headers: {'User-Agent': userAgent},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LrclibResponse.fromJson(data);
      }
    } on SocketException {
      // Offline / network failure
      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      debugPrint('[LrclibClient] _getExact error: $e');
      return null;
    }
    return null;
  }

  /// Search lookup via `/api/search` with candidate ranking
  Future<LrclibResponse?> _searchBest({
    required String trackName,
    required String artistName,
    Duration? duration,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/search').replace(queryParameters: {
        'track_name': trackName,
        'artist_name': artistName,
      });

      final response = await _client.get(
        uri,
        headers: {'User-Agent': userAgent},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        if (list.isEmpty) return null;

        final candidates = list
            .map((item) => LrclibResponse.fromJson(item as Map<String, dynamic>))
            .where((r) => r.hasLyrics || r.instrumental)
            .toList();

        if (candidates.isEmpty) return null;

        // If duration is provided, score candidate by duration delta and synced preference
        if (duration != null && duration.inSeconds > 0) {
          final targetSec = duration.inSeconds.toDouble();
          candidates.sort((a, b) {
            final aDelta = ((a.duration ?? targetSec) - targetSec).abs();
            final bDelta = ((b.duration ?? targetSec) - targetSec).abs();

            // Synced lyrics preferred if duration is close
            if ((aDelta - bDelta).abs() < 5) {
              if (a.isSynced && !b.isSynced) return -1;
              if (!a.isSynced && b.isSynced) return 1;
            }
            return aDelta.compareTo(bDelta);
          });
        } else {
          // Prefer synced lyrics first
          candidates.sort((a, b) {
            if (a.isSynced && !b.isSynced) return -1;
            if (!a.isSynced && b.isSynced) return 1;
            return 0;
          });
        }

        return candidates.first;
      }
    } on SocketException {
      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      debugPrint('[LrclibClient] _searchBest error: $e');
      return null;
    }
    return null;
  }

  void close() {
    _client.close();
  }
}
