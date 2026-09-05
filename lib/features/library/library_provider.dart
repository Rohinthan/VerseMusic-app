import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/library/library_scanner.dart';
import '../../core/library/song_model.dart';

class LibraryState {
  final bool isLoading;
  final List<Song> songs;
  final String? error;
  final List<String> directories;

  const LibraryState({
    this.isLoading = false,
    this.songs = const [],
    this.error,
    this.directories = const [],
  });

  LibraryState copyWith({
    bool? isLoading,
    List<Song>? songs,
    String? error,
    List<String>? directories,
  }) {
    return LibraryState(
      isLoading: isLoading ?? this.isLoading,
      songs: songs ?? this.songs,
      error: error,
      directories: directories ?? this.directories,
    );
  }
}

class LibraryNotifier extends Notifier<LibraryState> {
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
      state = state.copyWith(
        isLoading: false,
        songs: songs,
        directories: customDirs ?? state.directories,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to scan library: $e',
      );
    }
  }
}

final libraryScannerProvider = Provider<LibraryScanner>((ref) {
  return LibraryScanner.create();
});

final libraryNotifierProvider =
    NotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);
