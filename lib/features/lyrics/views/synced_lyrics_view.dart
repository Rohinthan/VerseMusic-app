import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lyrics_provider.dart';

class SyncedLyricsView extends ConsumerStatefulWidget {
  const SyncedLyricsView({super.key});

  @override
  ConsumerState<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends ConsumerState<SyncedLyricsView> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _lineKeys = [];
  bool _isUserScrolling = false;
  Timer? _userScrollDebounce;

  @override
  void dispose() {
    _userScrollDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(int index) {
    if (_isUserScrolling || !_scrollController.hasClients) return;
    if (index < 0 || index >= _lineKeys.length) return;

    final key = _lineKeys[index];
    final currentContext = key.currentContext;
    if (currentContext != null) {
      Scrollable.ensureVisible(
        currentContext,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
        alignment: 0.38, // Keep active line in comfortable upper-third focus
      );
    }
  }

  void _onUserScrollStart() {
    setState(() {
      _isUserScrolling = true;
    });
    _userScrollDebounce?.cancel();
    _userScrollDebounce = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isUserScrolling = false;
        });
        final activeIndex = ref.read(lyricsNotifierProvider).activeLineIndex;
        _scrollToActiveLine(activeIndex);
      }
    });
  }

  void _resumeAutoScroll() {
    _userScrollDebounce?.cancel();
    setState(() {
      _isUserScrolling = false;
    });
    final activeIndex = ref.read(lyricsNotifierProvider).activeLineIndex;
    _scrollToActiveLine(activeIndex);
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsNotifierProvider);

    // Listen for active line changes and auto-scroll
    ref.listen(lyricsNotifierProvider.select((s) => s.activeLineIndex), (prev, next) {
      if (next >= 0 && next != prev) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveLine(next);
        });
      }
    });

    if (lyricsState.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1DB954)),
            SizedBox(height: 16),
            Text(
              'Searching for lyrics...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (lyricsState.isInstrumental) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1DB954).withAlpha(25),
                  border: Border.all(color: const Color(0xFF1DB954).withAlpha(60)),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 36,
                  color: Color(0xFF1DB954),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Instrumental Track',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This track contains no lyrics.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(140),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(lyricsNotifierProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white70),
                label: const Text(
                  'Search Again',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withAlpha(50)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!lyricsState.hasLyrics) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lyrics_outlined,
                size: 56,
                color: Colors.white.withAlpha(60),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Lyrics Available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Could not find lyrics locally or on LRCLIB.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(140),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(lyricsNotifierProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white70),
                label: const Text(
                  'Search Online Again',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withAlpha(50)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lines = lyricsState.lyrics.lines;
    final isSynced = lyricsState.isSynced;

    // Ensure we have a GlobalKey for each line (used for synced scrolling)
    if (isSynced) {
      while (_lineKeys.length < lines.length) {
        _lineKeys.add(GlobalKey());
      }
      if (_lineKeys.length > lines.length) {
        _lineKeys.removeRange(lines.length, _lineKeys.length);
      }
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (isSynced &&
            notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          _onUserScrollStart();
        }
        return false;
      },
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isSynced ? MediaQuery.of(context).size.height * 0.25 : 32,
            ),
            // Total items: lyric lines + 1 footer attribution item
            itemCount: lines.length + 1,
            itemBuilder: (context, index) {
              // Footer item: Source attribution & refresh
              if (index == lines.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        lyricsState.lyricsFilePath != null || lyricsState.sourceLabel.contains('Local')
                            ? Icons.folder_outlined
                            : Icons.cloud_done_outlined,
                        size: 14,
                        color: Colors.white.withAlpha(100),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        lyricsState.sourceLabel,
                        style: TextStyle(
                          color: Colors.white.withAlpha(110),
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          ref.read(lyricsNotifierProvider.notifier).refresh();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: Colors.white.withAlpha(120),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final line = lines[index];
              final isActive = isSynced && index == lyricsState.activeLineIndex;
              final isPast = isSynced && index < lyricsState.activeLineIndex;

              return Padding(
                key: isSynced ? _lineKeys[index] : null,
                padding: EdgeInsets.symmetric(vertical: isSynced ? 10 : 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: isSynced
                      ? () {
                          ref.read(lyricsNotifierProvider.notifier).seekToLine(index);
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    alignment: isSynced ? Alignment.centerLeft : Alignment.center,
                    child: Text(
                      line.text.isEmpty ? '♪' : line.text,
                      textAlign: isSynced ? TextAlign.left : TextAlign.center,
                      style: TextStyle(
                        fontSize: isSynced
                            ? (isActive ? 22 : 17)
                            : 16,
                        height: 1.5,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: !isSynced
                            ? Colors.white.withAlpha(210)
                            : (isActive
                                ? const Color(0xFF1DB954)
                                : isPast
                                    ? Colors.white.withAlpha(90)
                                    : Colors.white.withAlpha(160)),
                        shadows: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF1DB954).withAlpha(80),
                                  blurRadius: 18,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating "Sync" Pill when user has manually scrolled away
          if (isSynced && _isUserScrolling && lyricsState.activeLineIndex >= 0)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _resumeAutoScroll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(120),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sync_rounded, color: Colors.black, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Sync to active line',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
