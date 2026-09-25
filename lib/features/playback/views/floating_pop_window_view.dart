import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/window/window_service.dart';
import '../playback_provider.dart';

/// Notification-card styled floating pop-up player window for desktop playback.
class FloatingPopWindowView extends ConsumerWidget {
  const FloatingPopWindowView({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

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

    final hasArt = currentSong?.artPath != null && File(currentSong!.artPath!).existsSync();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Ambient Blurred Artwork / Glow Backdrop
            if (hasArt)
              Image.file(
                File(currentSong!.artPath!),
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.3),
                      const Color(0xFF1E1E1E),
                      const Color(0xFF121212),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

            // 2. Frosted Blur Filter
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                color: const Color(0xCC161616),
              ),
            ),

            // 3. Notification Card Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Notification Header & Window Controls
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 11,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'VERSE MUSIC',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '• Now Playing',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Colors.white54,
                        ),
                      ),
                      const Spacer(),
                      // Expand to Full Window
                      IconButton(
                        tooltip: 'Expand to full window',
                        icon: const Icon(
                          Icons.open_in_full_rounded,
                          size: 13,
                          color: Colors.white70,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                        onPressed: () => WindowService.exitMiniWindowMode(ref),
                      ),
                    ],
                  ),

                  // Middle Row: Album Artwork, Title/Artist & Media Controls
                  Row(
                    children: [
                      // Album Artwork (Notification square)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF242424),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasArt
                            ? Image.file(
                                File(currentSong!.artPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.music_note_rounded,
                                  color: accentColor,
                                  size: 24,
                                ),
                              )
                            : Icon(
                                Icons.music_note_rounded,
                                color: accentColor,
                                size: 24,
                              ),
                      ),
                      const SizedBox(width: 10),

                      // Title & Artist
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong?.title ?? 'No song playing',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentSong?.artist ?? 'Select a song to start',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Notification Transport Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Previous Track
                          IconButton(
                            tooltip: 'Previous song',
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: () => notifier.playPrevious(),
                          ),
                          const SizedBox(width: 4),

                          // Play / Pause Circle
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: IconButton(
                              tooltip: isPlaying ? 'Pause' : 'Play',
                              icon: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                size: 21,
                                color: Colors.black,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () => notifier.togglePlayPause(),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Next Track
                          IconButton(
                            tooltip: 'Next song',
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              size: 22,
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

                  // Bottom: Interactive Progress Bar & Time Labels
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (details) {
                          if (durationMs > 0) {
                            final box = context.findRenderObject() as RenderBox?;
                            if (box != null) {
                              final localX = details.localPosition.dx;
                              final width = box.size.width - 24;
                              final pct = (localX / width).clamp(0.0, 1.0);
                              notifier.seek(Duration(milliseconds: (pct * durationMs).toInt()));
                            }
                          }
                        },
                        onTapDown: (details) {
                          if (durationMs > 0) {
                            final box = context.findRenderObject() as RenderBox?;
                            if (box != null) {
                              final localX = details.localPosition.dx;
                              final width = box.size.width - 24;
                              final pct = (localX / width).clamp(0.0, 1.0);
                              notifier.seek(Duration(milliseconds: (pct * durationMs).toInt()));
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 3.0,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playbackState.position),
                            style: const TextStyle(fontSize: 9.5, color: Colors.white54),
                          ),
                          Text(
                            _formatDuration(playbackState.duration),
                            style: const TextStyle(fontSize: 9.5, color: Colors.white54),
                          ),
                        ],
                      ),
                    ],
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
