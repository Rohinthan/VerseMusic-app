import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path/path.dart' as p;
import 'core/library/song_model.dart';
import 'features/library/library_provider.dart';
import 'features/playback/playback_provider.dart';
import 'widgets/animated_equalizer.dart';
import 'widgets/dynamic_mini_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Linux desktop audio backend via libmpv
  if (Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized(
      linux: true,
      windows: false,
      android: false,
      iOS: false,
      macOS: false,
    );
  }

  runApp(
    const ProviderScope(
      child: VerseMusicApp(),
    ),
  );
}

class VerseMusicApp extends StatelessWidget {
  const VerseMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Verse Music Player',
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
      home: const MainLibraryScreen(),
    );
  }
}

class MainLibraryScreen extends ConsumerWidget {
  const MainLibraryScreen({super.key});

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds == 0) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final playback = ref.watch(playbackNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verse'),
                Text(
                  'Local Music Player (${Platform.operatingSystem})',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withAlpha(160),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
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
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan Library',
            onPressed: libraryState.isLoading
                ? null
                : () => ref.read(libraryNotifierProvider.notifier).scan(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Builder(
              builder: (context) {
                if (libraryState.isLoading && libraryState.songs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF1DB954)),
                        SizedBox(height: 16),
                        Text(
                          'Scanning local audio files...',
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
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.redAccent),
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
                    // Dynamic Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: const Color(0xFF181818),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.library_music_rounded,
                                  size: 16, color: Color(0xFF1DB954)),
                              const SizedBox(width: 8),
                              Text(
                                '${libraryState.songs.length} TRACKS AVAILABLE',
                                style: const TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (playback.hasCurrentSong)
                            Row(
                              children: [
                                Text(
                                  playback.isPlaying ? 'PLAYING' : 'PAUSED',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: playback.isPlaying
                                        ? const Color(0xFF1DB954)
                                        : Colors.white54,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                AnimatedEqualizer(
                                  isPlaying: playback.isPlaying,
                                  size: 14,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Song List
                    Expanded(
                      child: ListView.separated(
                        // Add bottom padding so the list doesn't get obscured by mini-player
                        padding: EdgeInsets.only(
                          bottom: playback.hasCurrentSong ? 80 : 16,
                        ),
                        itemCount: libraryState.songs.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: Colors.white.withAlpha(12),
                        ),
                        itemBuilder: (context, index) {
                          final song = libraryState.songs[index];
                          final isCurrent = playback.currentSong?.id == song.id;
                          final isPlayingThis = isCurrent && playback.isPlaying;
                          final ext = p
                              .extension(song.filePath)
                              .toUpperCase()
                              .replaceAll('.', '');

                          return ListTile(
                            selected: isCurrent,
                            selectedTileColor:
                                const Color(0xFF1DB954).withAlpha(15),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 46,
                                height: 46,
                                color: const Color(0xFF282828),
                                child: song.embeddedArt != null
                                    ? Image.memory(
                                        song.embeddedArt!,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        isCurrent
                                            ? Icons.play_arrow_rounded
                                            : Icons.music_note_rounded,
                                        color: isCurrent
                                            ? const Color(0xFF1DB954)
                                            : Colors.white54,
                                        size: 24,
                                      ),
                              ),
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent
                                    ? const Color(0xFF1DB954)
                                    : Colors.white,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${song.artist} • ${song.album}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent
                                    ? const Color(0xFF1DB954).withAlpha(200)
                                    : Colors.white.withAlpha(150),
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isPlayingThis) ...[
                                  const AnimatedEqualizer(
                                    isPlaying: true,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(15),
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
                                    color: Colors.white.withAlpha(150),
                                    fontSize: 12,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    size: 18,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () =>
                                      _showSongDetails(context, song),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (isCurrent) {
                                ref
                                    .read(playbackNotifierProvider.notifier)
                                    .togglePlayPause();
                              } else {
                                ref
                                    .read(playbackNotifierProvider.notifier)
                                    .playSong(
                                      song,
                                      playlist: libraryState.songs,
                                    );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Dynamic Floating Mini-Player at bottom
          if (playback.hasCurrentSong)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DynamicMiniPlayer(),
            ),
        ],
      ),
    );
  }

  void _showSongDetails(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF242424),
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
                        child:
                            const Icon(Icons.music_note, color: Colors.white54),
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
                  'File Path:',
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
