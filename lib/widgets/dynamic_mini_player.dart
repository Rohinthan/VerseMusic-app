import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/playback/playback_provider.dart';
import 'album_art_widget.dart';
import 'animated_equalizer.dart';
import 'dynamic_now_playing_sheet.dart';

class DynamicMiniPlayer extends ConsumerWidget {
  const DynamicMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackNotifierProvider);
    final song = playback.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const DynamicNowPlayingSheet(),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linear Progress Bar on the top rim
            LinearProgressIndicator(
              value: playback.progress,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
              minHeight: 2.5,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Album Art Thumbnail
                  Hero(
                    tag: 'now_playing_art_${song.id}',
                    child: AlbumArtWidget(
                      song: song,
                      size: 44,
                      borderRadius: 6,
                      iconSize: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: playback.isPlaying
                                ? const Color(0xFF1DB954)
                                : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withAlpha(160),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pulsing Equalizer indicator
                  if (playback.isPlaying) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: AnimatedEqualizer(
                        isPlaying: true,
                        size: 16,
                        color: Color(0xFF1DB954),
                      ),
                    ),
                  ],

                  // Play/Pause Button
                  IconButton(
                    iconSize: 30,
                    icon: playback.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1DB954),
                            ),
                          )
                        : Icon(
                            playback.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                    onPressed: () => ref
                        .read(playbackNotifierProvider.notifier)
                        .togglePlayPause(),
                  ),

                  // Skip Next Button
                  IconButton(
                    iconSize: 26,
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () =>
                        ref.read(playbackNotifierProvider.notifier).playNext(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
