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
                'Place a .lrc file beside your audio track to view live synced lyrics.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(140),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lines = lyricsState.lyrics.lines;

    // Ensure we have a GlobalKey for each line
    while (_lineKeys.length < lines.length) {
      _lineKeys.add(GlobalKey());
    }
    if (_lineKeys.length > lines.length) {
      _lineKeys.removeRange(lines.length, _lineKeys.length);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
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
              vertical: MediaQuery.of(context).size.height * 0.25,
            ),
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              final isActive = index == lyricsState.activeLineIndex;
              final isPast = index < lyricsState.activeLineIndex;

              return Padding(
                key: _lineKeys[index],
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ref.read(lyricsNotifierProvider.notifier).seekToLine(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      line.text.isEmpty ? '♪' : line.text,
                      style: TextStyle(
                        fontSize: isActive ? 22 : 17,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF1DB954)
                            : isPast
                                ? Colors.white.withAlpha(90)
                                : Colors.white.withAlpha(160),
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
          if (_isUserScrolling && lyricsState.activeLineIndex >= 0)
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
