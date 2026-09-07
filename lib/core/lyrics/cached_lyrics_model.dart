import 'package:flutter/foundation.dart';

/// Database model for persistently caching fetched lyrics in SQLite.
@immutable
class CachedLyricsRecord {
  final String songId;
  final String? plainLyrics;
  final String? syncedLyrics;
  final bool isSynced;
  final bool isInstrumental;
  final String source; // 'local', 'lrclib', etc.
  final DateTime fetchedAt;

  const CachedLyricsRecord({
    required this.songId,
    this.plainLyrics,
    this.syncedLyrics,
    this.isSynced = false,
    this.isInstrumental = false,
    required this.source,
    required this.fetchedAt,
  });

  Map<String, dynamic> toMap() => {
        'songId': songId,
        'plainLyrics': plainLyrics,
        'syncedLyrics': syncedLyrics,
        'isSynced': isSynced ? 1 : 0,
        'isInstrumental': isInstrumental ? 1 : 0,
        'source': source,
        'fetchedAtMs': fetchedAt.millisecondsSinceEpoch,
      };

  factory CachedLyricsRecord.fromMap(Map<String, dynamic> map) =>
      CachedLyricsRecord(
        songId: map['songId'] as String,
        plainLyrics: map['plainLyrics'] as String?,
        syncedLyrics: map['syncedLyrics'] as String?,
        isSynced: (map['isSynced'] as int? ?? 0) == 1,
        isInstrumental: (map['isInstrumental'] as int? ?? 0) == 1,
        source: map['source'] as String? ?? 'unknown',
        fetchedAt:
            DateTime.fromMillisecondsSinceEpoch(map['fetchedAtMs'] as int? ?? 0),
      );
}
