import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/audio/playback_state.dart';
import '../features/playback/playback_provider.dart';
import 'album_art_widget.dart';
import 'animated_equalizer.dart';

class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key});

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds == 0) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackNotifierProvider);
    final upcoming = playback.upcomingSongs;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Top drag indicator bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Play Queue',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${upcoming.length} upcoming tracks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(150),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (upcoming.isNotEmpty)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1DB954),
                        ),
                        onPressed: () {
                          ref.read(playbackNotifierProvider.notifier).clearQueue();
                        },
                        child: const Text('Clear'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white12),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // NOW PLAYING Section
                if (playback.hasCurrentSong) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'NOW PLAYING',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF1DB954).withAlpha(40),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        AlbumArtWidget(
                          song: playback.currentSong!,
                          size: 48,
                          borderRadius: 6,
                          fallbackIcon: Icons.music_note_rounded,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playback.currentSong!.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF1DB954),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${playback.currentSong!.artist} • ${playback.currentSong!.album}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(160),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (playback.isPlaying) ...[
                          const SizedBox(width: 8),
                          const AnimatedEqualizer(isPlaying: true, size: 16),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // NEXT UP Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NEXT UP (${upcoming.length})',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withAlpha(160),
                        ),
                      ),
                      if (upcoming.isNotEmpty)
                        Text(
                          'Drag to reorder',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withAlpha(100),
                          ),
                        ),
                    ],
                  ),
                ),

                if (upcoming.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.queue_music_rounded,
                            size: 56,
                            color: Colors.white.withAlpha(60),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Queue is empty',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tracks you play or add will appear here.',
                            style: TextStyle(
                              color: Colors.white.withAlpha(140),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upcoming.length,
                    onReorderItem: (oldIndex, newIndex) {
                      ref
                          .read(playbackNotifierProvider.notifier)
                          .reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = upcoming[index];

                      return ListTile(
                        key: ValueKey('queue_item_${song.id}_$index'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                              ),
                            ),
                            AlbumArtWidget(
                              song: song,
                              size: 40,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withAlpha(140),
                            fontSize: 11,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDuration(song.duration),
                              style: TextStyle(
                                color: Colors.white.withAlpha(140),
                                fontSize: 11,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 18,
                                color: Colors.white38,
                              ),
                              onPressed: () {
                                ref
                                    .read(playbackNotifierProvider.notifier)
                                    .removeFromQueue(index);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          ref
                              .read(playbackNotifierProvider.notifier)
                              .jumpToQueueItem(index);
                        },
                      );
                    },
                  ),
              ],
            ),
          ),

          // Bottom Quick Bar: Shuffle & Repeat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF141414),
              border: Border(top: BorderSide(color: Colors.white10, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Shuffle Button
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: playback.isShuffled
                        ? const Color(0xFF1DB954)
                        : Colors.white60,
                  ),
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: playback.isShuffled
                        ? const Color(0xFF1DB954)
                        : Colors.white60,
                    size: 20,
                  ),
                  label: Text(
                    playback.isShuffled ? 'Shuffle On' : 'Shuffle Off',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    ref.read(playbackNotifierProvider.notifier).toggleShuffle();
                  },
                ),

                // Repeat Button
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: playback.repeatMode != AudioRepeatMode.off
                        ? const Color(0xFF1DB954)
                        : Colors.white60,
                  ),
                  icon: Icon(
                    playback.repeatMode == AudioRepeatMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: playback.repeatMode != AudioRepeatMode.off
                        ? const Color(0xFF1DB954)
                        : Colors.white60,
                    size: 20,
                  ),
                  label: Text(
                    playback.repeatMode == AudioRepeatMode.one
                        ? 'Repeat One'
                        : (playback.repeatMode == AudioRepeatMode.all
                            ? 'Repeat All'
                            : 'Repeat Off'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    ref.read(playbackNotifierProvider.notifier).cycleRepeatMode();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
