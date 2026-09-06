import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/playback/playback_provider.dart';
import 'album_art_widget.dart';
import 'blurred_art_background.dart';

class DynamicNowPlayingSheet extends ConsumerStatefulWidget {
  const DynamicNowPlayingSheet({super.key});

  @override
  ConsumerState<DynamicNowPlayingSheet> createState() =>
      _DynamicNowPlayingSheetState();
}

class _DynamicNowPlayingSheetState extends ConsumerState<DynamicNowPlayingSheet> {
  double? _dragPositionSeconds;

  String _formatTime(Duration duration) {
    final mins = duration.inMinutes;
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackNotifierProvider);
    final song = playback.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final totalSeconds = playback.duration.inSeconds.toDouble();
    final currentSeconds = _dragPositionSeconds ??
        playback.position.inSeconds.toDouble().clamp(0.0, totalSeconds > 0 ? totalSeconds : 1.0);

    return BlurredArtBackground(
      song: song,
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'PLAYING FROM LOCAL STORAGE',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            if (playback.playlist.isNotEmpty)
              Text(
                'Track ${playback.currentIndex + 1} of ${playback.playlist.length}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF1DB954)),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Large Album Art with Shadow
              Center(
                child: Hero(
                  tag: 'now_playing_art_${song.id}',
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: MediaQuery.of(context).size.width * 0.75,
                    constraints: const BoxConstraints(
                      maxWidth: 340,
                      maxHeight: 340,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1DB954).withAlpha(35),
                          blurRadius: 36,
                          spreadRadius: 4,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: Colors.black.withAlpha(150),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AlbumArtWidget(
                      song: song,
                      size: 340,
                      borderRadius: 16,
                      fallbackIcon: Icons.music_note_rounded,
                      iconSize: 96,
                    ),
                  ),
                ),
              ),

              // Title & Artist
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withAlpha(180),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Dynamic Seek Bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                        elevation: 4,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withAlpha(40),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withAlpha(30),
                    ),
                    child: Slider(
                      min: 0.0,
                      max: totalSeconds > 0 ? totalSeconds : 1.0,
                      value: currentSeconds.clamp(0.0, totalSeconds > 0 ? totalSeconds : 1.0),
                      onChanged: (value) {
                        setState(() {
                          _dragPositionSeconds = value;
                        });
                      },
                      onChangeEnd: (value) {
                        ref
                            .read(playbackNotifierProvider.notifier)
                            .seek(Duration(seconds: value.round()));
                        setState(() {
                          _dragPositionSeconds = null;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(Duration(seconds: currentSeconds.round())),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withAlpha(150),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          _formatTime(playback.duration),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withAlpha(150),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Transport Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.replay_10_rounded),
                    color: Colors.white70,
                    tooltip: 'Rewind 10s',
                    onPressed: () {
                      final target = (playback.position - const Duration(seconds: 10));
                      ref.read(playbackNotifierProvider.notifier).seek(
                            target.isNegative ? Duration.zero : target,
                          );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: Colors.white,
                    tooltip: 'Previous Track',
                    onPressed: () =>
                        ref.read(playbackNotifierProvider.notifier).playPrevious(),
                  ),
                  const SizedBox(width: 16),

                  // Large Circular Play/Pause button with Spotify Green glow
                  GestureDetector(
                    onTap: () => ref
                        .read(playbackNotifierProvider.notifier)
                        .togglePlayPause(),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1DB954),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x661DB954),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: playback.isLoading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.black,
                                ),
                              )
                            : Icon(
                                playback.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 40,
                                color: Colors.black,
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),
                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.skip_next_rounded),
                    color: Colors.white,
                    tooltip: 'Next Track',
                    onPressed: () =>
                        ref.read(playbackNotifierProvider.notifier).playNext(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.forward_10_rounded),
                    color: Colors.white70,
                    tooltip: 'Forward 10s',
                    onPressed: () {
                      final target = (playback.position + const Duration(seconds: 10));
                      ref.read(playbackNotifierProvider.notifier).seek(
                            target > playback.duration ? playback.duration : target,
                          );
                    },
                  ),
                ],
              ),

              // Volume Slider Row
              Row(
                children: [
                  Icon(
                    Icons.volume_down_rounded,
                    size: 20,
                    color: Colors.white.withAlpha(140),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        activeTrackColor: Colors.white70,
                        inactiveTrackColor: Colors.white.withAlpha(30),
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        min: 0.0,
                        max: 1.0,
                        value: playback.volume,
                        onChanged: (val) => ref
                            .read(playbackNotifierProvider.notifier)
                            .setVolume(val),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.volume_up_rounded,
                    size: 20,
                    color: Colors.white.withAlpha(140),
                  ),
                ],
              ),

              // Bottom Utilities Bar (Lyrics & Queue affordance)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.lyrics_outlined),
                      color: Colors.white60,
                      tooltip: 'Lyrics (Coming in v0.6)',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lyrics sync engine coming in v0.6'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded),
                      color: Colors.white60,
                      tooltip: 'Queue (Coming in v0.5)',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Queue management coming in v0.5'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
