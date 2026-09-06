import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/library/artist_model.dart';
import '../../../core/library/song_model.dart';
import '../../../widgets/animated_equalizer.dart';
import '../../playback/playback_provider.dart';
import '../library_provider.dart';

class ArtistDetailView extends ConsumerWidget {
  final Artist artist;

  const ArtistDetailView({
    super.key,
    required this.artist,
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

    final artistSongs = libraryState.songs
        .where((s) => s.artist.toLowerCase() == artist.name.toLowerCase())
        .toList();

    final songWithArt = artistSongs.where((s) => s.artPath != null).firstOrNull;
    final hasArt = songWithArt?.artPath != null &&
        File(songWithArt!.artPath!).existsSync();

    final isArtistPlaying = playback.isPlaying &&
        playback.currentSong != null &&
        artistSongs.any((s) => s.id == playback.currentSong!.id);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260.0,
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
                  // Blurred background
                  if (hasArt)
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Image.file(
                        File(songWithArt.artPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(color: const Color(0xFF1B2C24)),
                  // Gradient overlay
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
                  // Artist Circular Avatar & Header
                  SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF282828),
                                border: Border.all(
                                  color: const Color(0xFF1DB954),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1DB954).withAlpha(40),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: hasArt
                                    ? Image.file(
                                        File(songWithArt.artPath!),
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        Icons.person_rounded,
                                        size: 54,
                                        color: Colors.white54,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              artist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${artistSongs.length} tracks • ${artist.albumCount} ${artist.albumCount == 1 ? 'album' : 'albums'} • ${_formatTotalDuration(artistSongs)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
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
                    'ALL SONGS BY ${artist.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white.withAlpha(160),
                    ),
                  ),
                  if (artistSongs.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        if (isArtistPlaying) {
                          ref.read(playbackNotifierProvider.notifier).togglePlayPause();
                        } else {
                          ref.read(playbackNotifierProvider.notifier).playSong(
                                artistSongs.first,
                                playlist: artistSongs,
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
                          isArtistPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
                  final song = artistSongs[index];
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
                      song.album,
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
                              playlist: artistSongs,
                            );
                      }
                    },
                  );
                },
                childCount: artistSongs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
