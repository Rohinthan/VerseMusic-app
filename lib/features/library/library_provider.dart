import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/library/album_model.dart';
import '../../core/library/artist_model.dart';
import '../../core/library/library_scanner.dart';
import '../../core/library/song_model.dart';
import '../../core/storage/database_service.dart';

class LibraryState {
  final bool isLoading;
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final String? error;
  final List<String> directories;

  const LibraryState({
    this.isLoading = false,
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.error,
    this.directories = const [],
  });

  LibraryState copyWith({
    bool? isLoading,
    List<Song>? songs,
    List<Album>? albums,
    List<Artist>? artists,
    String? error,
    List<String>? directories,
  }) {
    return LibraryState(
      isLoading: isLoading ?? this.isLoading,
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      error: error,
      directories: directories ?? this.directories,
    );
  }
}

class LibraryNotifier extends Notifier<LibraryState> {
  final DatabaseService _dbService = DatabaseService();

  @override
  LibraryState build() {
    Future.microtask(() => scan());
    return const LibraryState();
  }

  Future<void> scan({List<String>? customDirs}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final scanner = ref.read(libraryScannerProvider);
      final songs = await scanner.scanLibrary(directories: customDirs);
      final albums = await _dbService.getAlbums();
      final artists = await _dbService.getArtists();

      state = state.copyWith(
        isLoading: false,
        songs: songs,
        albums: albums,
        artists: artists,
        directories: customDirs ?? state.directories,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to scan library: $e',
      );
    }
  }

  List<Song> getSongsForAlbum(String albumTitle) {
    return state.songs
        .where((s) => s.album.toLowerCase() == albumTitle.toLowerCase())
        .toList();
  }

  List<Song> getSongsForArtist(String artistName) {
    return state.songs
        .where((s) => s.artist.toLowerCase() == artistName.toLowerCase())
        .toList();
  }
}

final libraryScannerProvider = Provider<LibraryScanner>((ref) {
  return LibraryScanner.create();
});

final libraryNotifierProvider =
    NotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);
