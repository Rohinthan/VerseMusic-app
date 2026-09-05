import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'core/library/song_model.dart';
import 'features/library/library_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: LocalMusicPlayerApp(),
    ),
  );
}

class LocalMusicPlayerApp extends StatelessWidget {
  const LocalMusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954), // Spotify Green
          secondary: Color(0xFF1ED760),
          surface: Color(0xFF181818),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const LibraryVerificationScreen(),
    );
  }
}

class LibraryVerificationScreen extends ConsumerWidget {
  const LibraryVerificationScreen({super.key});

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds == 0) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Local Music Player'),
            Text(
              'v0.1 Skeleton & Platform Scan (${Platform.operatingSystem})',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withAlpha(160),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: libraryState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1DB954),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Rescan Library',
            onPressed: libraryState.isLoading
                ? null
                : () => ref.read(libraryNotifierProvider.notifier).scan(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (libraryState.isLoading && libraryState.songs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1DB954)),
                  SizedBox(height: 16),
                  Text(
                    'Scanning local audio library...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          if (libraryState.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      libraryState.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () =>
                          ref.read(libraryNotifierProvider.notifier).scan(),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (libraryState.songs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.music_off_outlined,
                      size: 64,
                      color: Colors.white.withAlpha(80),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No local audio files found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Platform.isAndroid
                          ? 'Ensure storage/media permissions are granted.'
                          : 'Place audio files in ~/Music or configure folders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withAlpha(160)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.search),
                      label: const Text('Scan Library'),
                      onPressed: () =>
                          ref.read(libraryNotifierProvider.notifier).scan(),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF181818),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FOUND ${libraryState.songs.length} TRACKS',
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1DB954),
                      ),
                    ),
                    if (libraryState.isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1DB954),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: libraryState.songs.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: Colors.white.withAlpha(15),
                  ),
                  itemBuilder: (context, index) {
                    final song = libraryState.songs[index];
                    final ext = p.extension(song.filePath).toUpperCase().replaceAll('.', '');

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 48,
                          height: 48,
                          color: const Color(0xFF282828),
                          child: song.embeddedArt != null
                              ? Image.memory(
                                  song.embeddedArt!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.music_note,
                                  color: Colors.white54,
                                ),
                        ),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${song.artist} • ${song.album}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withAlpha(160),
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ext,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(song.duration),
                            style: TextStyle(
                              color: Colors.white.withAlpha(160),
                              fontSize: 12,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showSongDetails(context, song),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSongDetails(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (song.embeddedArt != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          song.embeddedArt!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.white54),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1DB954),
                            ),
                          ),
                          Text(
                            song.album,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha(160),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                Text(
                  'Path:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withAlpha(140),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  song.filePath,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ID: ${song.id}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.white.withAlpha(100),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
