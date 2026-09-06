import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/library/album_model.dart';
import '../../../core/library/song_model.dart';
import '../../../widgets/album_art_widget.dart';
import '../../../widgets/animated_equalizer.dart';
import '../../playback/playback_provider.dart';
import '../library_provider.dart';

class AlbumDetailView extends ConsumerWidget {
  final Album album;

  const AlbumDetailView({
    super.key,
    required this.album,
  });

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds == 0) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatTotalDuration(List<Song> songs) {
    final totalSec = songs.fold<int>(0, (sum, s) => sum + s.duration.inSeconds);
    final hours = totalSec ~/ 3600;
    final mins = (totalSec % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours hr $mins min';
    }
    return '$mins min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final playback = ref.watch(playbackNotifierProvider);

    final albumSongs = libraryState.songs
        .where((s) => s.album.toLowerCase() == album.title.toLowerCase())
        .toList();

    final hasArt = album.artPath != null && File(album.artPath!).existsSync();
    final firstSongWithArt = albumSongs.where((s) => s.artPath != null).firstOrNull;

    final isAlbumPlaying = playback.isPlaying &&
        playback.currentSong != null &&
        albumSongs.any((s) => s.id == playback.currentSong!.id);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: const Color(0xFF181818),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred subtle art backdrop
                  if (hasArt || (firstSongWithArt != null && firstSongWithArt.artPath != null))
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Image.file(
                        File(album.artPath ?? firstSongWithArt!.artPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF1E2822),
                    ),
                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(100),
                          const Color(0xFF121212).withAlpha(220),
                          const Color(0xFF121212),
                        ],
                      ),
                    ),
                  ),
                  // Album art & metadata
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48, left: 24, right: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 130,
                              height: 130,
                              child: hasArt
                                  ? Image.file(File(album.artPath!), fit: BoxFit.cover)
                                  : (firstSongWithArt != null
                                      ? AlbumArtWidget(song: firstSongWithArt, size: 130)
                                      : Container(
                                          color: const Color(0xFF282828),
                                          child: const Icon(
                                            Icons.album_rounded,
                                            size: 64,
                                            color: Colors.white38,
                                          ),
                                        )),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  album.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  album.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1DB954),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${albumSongs.length} songs • ${_formatTotalDuration(albumSongs)}',
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
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Control Bar: Big Green Play/Pause button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TRACKS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white.withAlpha(160),
                    ),
                  ),
                  if (albumSongs.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        if (isAlbumPlaying) {
                          ref.read(playbackNotifierProvider.notifier).togglePlayPause();
                        } else {
                          ref.read(playbackNotifierProvider.notifier).playSong(
                                albumSongs.first,
                                playlist: albumSongs,
                              );
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1DB954),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x551DB954),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isAlbumPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Songs List
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: playback.hasCurrentSong ? 88.0 : 24.0,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = albumSongs[index];
                  final isCurrent = playback.currentSong?.id == song.id;
                  final isPlayingThis = isCurrent && playback.isPlaying;

                  return ListTile(
                    selected: isCurrent,
                    selectedTileColor: const Color(0xFF1DB954).withAlpha(15),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: SizedBox(
                      width: 32,
                      child: Center(
                        child: isPlayingThis
                            ? const AnimatedEqualizer(isPlaying: true, size: 14)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent
                                      ? const Color(0xFF1DB954)
                                      : Colors.white.withAlpha(140),
                                ),
                              ),
                      ),
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent ? const Color(0xFF1DB954) : Colors.white,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(140),
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      _formatDuration(song.duration),
                      style: TextStyle(
                        color: Colors.white.withAlpha(140),
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    onTap: () {
                      if (isCurrent) {
                        ref.read(playbackNotifierProvider.notifier).togglePlayPause();
                      } else {
                        ref.read(playbackNotifierProvider.notifier).playSong(
                              song,
                              playlist: albumSongs,
                            );
                      }
                    },
                  );
                },
                childCount: albumSongs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
