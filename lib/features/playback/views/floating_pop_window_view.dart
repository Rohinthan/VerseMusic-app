import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/playback_state.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/window/window_service.dart';
import '../playback_provider.dart';

/// Sleek, compact floating pop-up window view for desktop playback.
class FloatingPopWindowView extends ConsumerWidget {
  const FloatingPopWindowView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackNotifierProvider);
    final notifier = ref.read(playbackNotifierProvider.notifier);
    final accentColor = ref.watch(accentColorProvider);

    final currentSong = playbackState.currentSong;
    final isPlaying = playbackState.isPlaying;

    final positionMs = playbackState.position.inMilliseconds.toDouble();
    final durationMs = playbackState.duration.inMilliseconds.toDouble();
    final progress = (durationMs > 0) ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Bar: Brand & Window Restore Controls
            Row(
              children: [
                Icon(
                  Icons.music_note_rounded,
                  size: 13,
                  color: accentColor,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Verse Music',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                // Expand / Restore Button
                IconButton(
                  tooltip: 'Expand to full window',
                  icon: const Icon(
                    Icons.open_in_full_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: () => WindowService.exitMiniWindowMode(ref),
                ),
              ],
            ),

            // Middle Row: Artwork, Song Info & Controls
            Row(
              children: [
                // Album Art
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: currentSong?.artPath != null &&
                          File(currentSong!.artPath!).existsSync()
                      ? Image.file(
                          File(currentSong.artPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.music_note_rounded,
                            color: accentColor,
                            size: 22,
                          ),
                        )
                      : Icon(
                          Icons.music_note_rounded,
                          color: accentColor,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 10),

                // Song Title & Artist
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong?.title ?? 'No song playing',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentSong?.artist ?? 'Select a song to start',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Playback Transport Controls (Change Song at the Top)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Previous Song
                    IconButton(
                      tooltip: 'Previous song',
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => notifier.playPrevious(),
                    ),
                    const SizedBox(width: 4),

                    // Play / Pause Button
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
                        tooltip: isPlaying ? 'Pause' : 'Play',
                        icon: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 19,
                          color: Colors.black,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => notifier.togglePlayPause(),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Next Song (Change Song)
                    IconButton(
                      tooltip: 'Next song',
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => notifier.playNext(),
                    ),
                  ],
                ),
              ],
            ),

            // Bottom Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
