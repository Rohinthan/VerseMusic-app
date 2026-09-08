import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/library/song_model.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../widgets/album_art_widget.dart';
import '../../../widgets/animated_equalizer.dart';
import '../../playback/playback_provider.dart';
import '../library_provider.dart';

class SongsTabView extends ConsumerWidget {
  const SongsTabView({super.key});

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds == 0) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final currentSongId = ref.watch(playbackNotifierProvider.select((s) => s.currentSong?.id));
    final isPlaying = ref.watch(playbackNotifierProvider.select((s) => s.isPlaying));
    final hasCurrentSong = ref.watch(playbackNotifierProvider.select((s) => s.hasCurrentSong));
    final accentColor = ref.watch(accentColorProvider);
    final isBright = ThemeData.estimateBrightnessForColor(accentColor) == Brightness.light;
    final onAccent = isBright ? Colors.black : Colors.white;

    if (libraryState.isLoading && libraryState.songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: accentColor),
            const SizedBox(height: 16),
            const Text(
              'Scanning local audio files...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
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
                'No songs found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add audio files to your music directories or tap rescan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withAlpha(160)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: onAccent,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Rescan Library'),
                onPressed: () =>
                    ref.read(libraryNotifierProvider.notifier).scan(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Sub-header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF181818),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${libraryState.songs.length} TRACKS',
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (hasCurrentSong)
                Row(
                  children: [
                    Text(
                      isPlaying ? 'PLAYING' : 'PAUSED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPlaying
                            ? accentColor
                            : Colors.white54,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedEqualizer(
                      isPlaying: isPlaying,
                      size: 14,
                      color: accentColor,
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Songs List
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.only(
              bottom: hasCurrentSong ? 88 : 16,
              top: 4,
            ),
            itemCount: libraryState.songs.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: Colors.white.withAlpha(10),
            ),
            itemBuilder: (context, index) {
              final song = libraryState.songs[index];
              final isCurrent = currentSongId == song.id;
              final isPlayingThis = isCurrent && isPlaying;
              final ext = p
                  .extension(song.filePath)
                  .toUpperCase()
                  .replaceAll('.', '');

              return ListTile(
                selected: isCurrent,
                selectedTileColor: accentColor.withAlpha(20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: AlbumArtWidget(
                  song: song,
                  size: 48,
                  borderRadius: 6,
                  fallbackIcon: isCurrent
                      ? Icons.play_arrow_rounded
                      : Icons.music_note_rounded,
                  iconSize: 24,
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent ? accentColor : Colors.white,
                    fontWeight:
                        isCurrent ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${song.artist} • ${song.album}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent
                        ? accentColor.withAlpha(200)
                        : Colors.white.withAlpha(150),
                    fontSize: 12,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPlayingThis) ...[
                      AnimatedEqualizer(
                        isPlaying: true,
                        size: 16,
                        color: accentColor,
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
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: Colors.white54,
                      ),
                      onPressed: () => _showSongDetails(context, ref, song, accentColor),
                    ),
                  ],
                ),
                onTap: () {
                  if (isCurrent) {
                    ref
                        .read(playbackNotifierProvider.notifier)
                        .togglePlayPause();
                  } else {
                    ref.read(playbackNotifierProvider.notifier).playSong(
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
  }

  void _showSongDetails(BuildContext context, WidgetRef ref, Song song, Color accentColor) {
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
                    AlbumArtWidget(
                      song: song,
                      size: 60,
                      borderRadius: 8,
                      iconSize: 28,
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
                            style: TextStyle(
                              fontSize: 14,
                              color: accentColor,
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
                ListTile(
                  leading: Icon(Icons.playlist_play_rounded, color: accentColor),
                  title: const Text('Play Next', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Insert this track to play next', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  onTap: () {
                    ref.read(playbackNotifierProvider.notifier).playNextInQueue(song);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Playing "${song.title}" next'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.queue_music_rounded, color: accentColor),
                  title: const Text('Add to Queue', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Append this track to end of queue', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  onTap: () {
                    ref.read(playbackNotifierProvider.notifier).addToQueue(song);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added "${song.title}" to queue'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
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
