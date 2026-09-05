import 'dart:io';
import 'dart:typed_data';
import 'song_model.dart';
import 'android_library_scanner.dart';
import 'linux_library_scanner.dart';

abstract class LibraryScanner {
  /// Scans the platform's music storage/directories and returns a list of songs.
  Future<List<Song>> scanLibrary({List<String>? directories});

  /// Extracts or retrieves embedded artwork for a specific song.
  Future<Uint8List?> getArtwork(Song song);

  /// Factory providing the platform-specific scanner.
  static LibraryScanner create() {
    if (Platform.isAndroid) {
      return AndroidLibraryScanner();
    } else if (Platform.isLinux) {
      return LinuxLibraryScanner();
    } else {
      // Default to directory scanner for desktop/other
      return LinuxLibraryScanner();
    }
  }
}
