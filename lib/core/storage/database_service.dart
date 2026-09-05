import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../library/album_model.dart';
import '../library/artist_model.dart';
import '../library/song_model.dart';

class DatabaseService {
  static Database? _database;
  static Directory? _artDirectory;

  static Future<void> initialize() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Directory> get artDirectory async {
    if (_artDirectory != null) return _artDirectory!;
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, 'album_art'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _artDirectory = dir;
    return _artDirectory!;
  }

  Future<Database> _initDatabase() async {
    await DatabaseService.initialize();
    final supportDir = await getApplicationSupportDirectory();
    final dbPath = p.join(supportDir.path, 'verse_library.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE songs (
            id TEXT PRIMARY KEY,
            filePath TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            album TEXT NOT NULL,
            durationMs INTEGER NOT NULL,
            trackNumber INTEGER,
            artPath TEXT,
            fileModifiedMs INTEGER NOT NULL,
            dateAddedMs INTEGER NOT NULL
          )
        ''');

        await db.execute(
            'CREATE INDEX idx_songs_artist ON songs(artist COLLATE NOCASE)');
        await db.execute(
            'CREATE INDEX idx_songs_album ON songs(album COLLATE NOCASE)');
        await db.execute(
            'CREATE INDEX idx_songs_title ON songs(title COLLATE NOCASE)');
      },
    );
  }

  /// Returns cached modified times for all songs in DB: filePath -> fileModifiedMs
  Future<Map<String, int>> getCachedFileModifiedTimes() async {
    final db = await database;
    final rows = await db.query(
      'songs',
      columns: ['filePath', 'fileModifiedMs'],
    );

    final map = <String, int>{};
    for (final r in rows) {
      final path = r['filePath'] as String?;
      final mod = r['fileModifiedMs'] as int?;
      if (path != null && mod != null) {
        map[path] = mod;
      }
    }
    return map;
  }

  /// Saves a cover image to disk cache and returns the saved file path
  Future<String?> saveArtBytes(String id, Uint8List artBytes) async {
    try {
      final dir = await artDirectory;
      final file = File(p.join(dir.path, '$id.jpg'));
      if (!await file.exists()) {
        await file.writeAsBytes(artBytes);
      }
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Fetches all cached songs ordered by title
  Future<List<Song>> getAllSongs() async {
    final db = await database;
    final rows = await db.query(
      'songs',
      orderBy: 'title COLLATE NOCASE ASC',
    );

    return rows.map((r) => Song.fromMap(r)).toList();
  }

  /// Batch insert or update songs
  Future<void> saveSongs(List<Song> songs) async {
    if (songs.isEmpty) return;
    final db = await database;
    final batch = db.batch();

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final s in songs) {
      batch.insert(
        'songs',
        {
          ...s.toMap(),
          'dateAddedMs': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Deletes songs that no longer exist on disk
  Future<void> pruneMissingSongs(Set<String> currentFilePaths) async {
    final db = await database;
    final cached = await db.query('songs', columns: ['id', 'filePath', 'artPath']);
    final batch = db.batch();

    for (final row in cached) {
      final path = row['filePath'] as String?;
      final id = row['id'] as String?;
      final artPath = row['artPath'] as String?;

      if (path != null && !currentFilePaths.contains(path)) {
        batch.delete('songs', where: 'id = ?', whereArgs: [id]);
        if (artPath != null) {
          try {
            final f = File(artPath);
            if (f.existsSync()) f.deleteSync();
          } catch (_) {}
        }
      }
    }

    await batch.commit(noResult: true);
  }

  /// Derives Albums from cached songs
  Future<List<Album>> getAlbums() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT 
        album as title,
        artist,
        artPath,
        COUNT(*) as songCount
      FROM songs
      GROUP BY album, artist
      ORDER BY album COLLATE NOCASE ASC
    ''');

    return rows.map((r) {
      final title = r['title'] as String? ?? 'Unknown Album';
      final artist = r['artist'] as String? ?? 'Unknown Artist';
      final artPath = r['artPath'] as String?;
      final count = r['songCount'] as int? ?? 0;
      final id = 'album_${title}_$artist'.toLowerCase().replaceAll(' ', '_');

      return Album(
        id: id,
        title: title,
        artist: artist,
        songCount: count,
        artPath: artPath,
      );
    }).toList();
  }

  /// Derives Artists from cached songs
  Future<List<Artist>> getArtists() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT 
        artist as name,
        COUNT(*) as songCount,
        COUNT(DISTINCT album) as albumCount
      FROM songs
      GROUP BY artist
      ORDER BY artist COLLATE NOCASE ASC
    ''');

    return rows.map((r) {
      final name = r['name'] as String? ?? 'Unknown Artist';
      final songCount = r['songCount'] as int? ?? 0;
      final albumCount = r['albumCount'] as int? ?? 0;
      final id = 'artist_$name'.toLowerCase().replaceAll(' ', '_');

      return Artist(
        id: id,
        name: name,
        songCount: songCount,
        albumCount: albumCount,
      );
    }).toList();
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
