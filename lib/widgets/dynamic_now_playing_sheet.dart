import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/audio/playback_state.dart';
import '../core/theme/theme_provider.dart';
import '../features/lyrics/views/synced_lyrics_view.dart';
import '../features/playback/playback_provider.dart';
import 'album_art_widget.dart';
import 'blurred_art_background.dart';
import 'queue_sheet.dart';

class DynamicNowPlayingSheet extends ConsumerStatefulWidget {
  const DynamicNowPlayingSheet({super.key});

  @override
  ConsumerState<DynamicNowPlayingSheet> createState() =>
      _DynamicNowPlayingSheetState();
}

class _DynamicNowPlayingSheetState extends ConsumerState<DynamicNowPlayingSheet> {
  double? _dragPositionSeconds;
  bool _showLyrics = false;

  String _formatTime(Duration duration) {
    final mins = duration.inMinutes;
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackNotifierProvider);
    final accentColor = ref.watch(accentColorProvider);
    final isBright = ThemeData.estimateBrightnessForColor(accentColor) == Brightness.light;
    final onAccent = isBright ? Colors.black : Colors.white;
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
                style: TextStyle(fontSize: 11, color: accentColor),
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
              // Central Display: Album Art or Synced Lyrics
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.42,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _showLyrics
                      ? const SyncedLyricsView(key: ValueKey('synced_lyrics'))
                      : Center(
                          key: const ValueKey('album_art_center'),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showLyrics = true;
                              });
                            },
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
                                      color: accentColor.withAlpha(35),
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

              // Transport Controls Row (Spotify Style: Shuffle, Previous, Play/Pause, Next, Repeat)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shuffle Button
                  IconButton(
                    iconSize: 26,
                    icon: const Icon(Icons.shuffle_rounded),
                    color: playback.isShuffled
                        ? accentColor
                        : Colors.white60,
                    tooltip: playback.isShuffled ? 'Shuffle: On' : 'Shuffle: Off',
                    onPressed: () => ref
                        .read(playbackNotifierProvider.notifier)
                        .toggleShuffle(),
                  ),

                  // Previous Track
                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: Colors.white,
                    tooltip: 'Previous Track',
                    onPressed: () =>
                        ref.read(playbackNotifierProvider.notifier).playPrevious(),
                  ),

                  // Large Circular Play/Pause button with dynamic accent glow
                  GestureDetector(
                    onTap: () => ref
                        .read(playbackNotifierProvider.notifier)
                        .togglePlayPause(),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withAlpha(85),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: playback.isLoading
                            ? SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: onAccent,
                                ),
                              )
                            : Icon(
                                playback.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 40,
                                color: onAccent,
                              ),
                      ),
                    ),
                  ),

                  // Next Track
                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.skip_next_rounded),
                    color: Colors.white,
                    tooltip: 'Next Track',
                    onPressed: () =>
                        ref.read(playbackNotifierProvider.notifier).playNext(),
                  ),

                  // Repeat Mode Button (Off / All / One)
                  IconButton(
                    iconSize: 26,
                    icon: Icon(
                      playback.repeatMode == AudioRepeatMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                    ),
                    color: playback.repeatMode != AudioRepeatMode.off
                        ? accentColor
                        : Colors.white60,
                    tooltip: playback.repeatMode == AudioRepeatMode.one
                        ? 'Repeat: One'
                        : (playback.repeatMode == AudioRepeatMode.all
                            ? 'Repeat: All'
                            : 'Repeat: Off'),
                    onPressed: () => ref
                        .read(playbackNotifierProvider.notifier)
                        .cycleRepeatMode(),
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

              // Bottom Utilities Bar (Lyrics & Queue Sheet)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        _showLyrics
                            ? Icons.lyrics_rounded
                            : Icons.lyrics_outlined,
                      ),
                      color: _showLyrics
                          ? accentColor
                          : Colors.white70,
                      tooltip: _showLyrics ? 'Show Artwork' : 'Live Synced Lyrics',
                      onPressed: () {
                        setState(() {
                          _showLyrics = !_showLyrics;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded),
                      color: playback.upcomingSongs.isNotEmpty
                          ? accentColor
                          : Colors.white70,
                      tooltip: 'Up Next Queue',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const QueueSheet(),
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
