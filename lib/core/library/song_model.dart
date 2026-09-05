import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class Song {
  final String id;
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final int? trackNumber;
  final Uint8List? embeddedArt;
  final String? artPath;
  final int fileModifiedMs;

  const Song({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.trackNumber,
    this.embeddedArt,
    this.artPath,
    this.fileModifiedMs = 0,
  });

  /// Deterministic ID from file path
  static String generateId(String path) {
    return md5.convert(utf8.encode(path)).toString();
  }

  Song copyWith({
    String? id,
    String? filePath,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    int? trackNumber,
    Uint8List? embeddedArt,
    String? artPath,
    int? fileModifiedMs,
  }) {
    return Song(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      trackNumber: trackNumber ?? this.trackNumber,
      embeddedArt: embeddedArt ?? this.embeddedArt,
      artPath: artPath ?? this.artPath,
      fileModifiedMs: fileModifiedMs ?? this.fileModifiedMs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': duration.inMilliseconds,
      'trackNumber': trackNumber,
      'artPath': artPath,
      'fileModifiedMs': fileModifiedMs,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map, {Uint8List? art}) {
    return Song(
      id: map['id'] as String,
      filePath: map['filePath'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      duration: Duration(milliseconds: map['durationMs'] as int? ?? 0),
      trackNumber: map['trackNumber'] as int?,
      embeddedArt: art,
      artPath: map['artPath'] as String?,
      fileModifiedMs: map['fileModifiedMs'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song($title by $artist - $filePath)';
}
