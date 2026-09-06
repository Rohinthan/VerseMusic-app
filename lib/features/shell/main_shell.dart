import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/dynamic_mini_player.dart';
import '../library/views/library_view.dart';
import '../navigation/navigation_provider.dart';
import '../playback/playback_provider.dart';
import '../search/search_view.dart';
import '../settings/settings_view.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationNotifierProvider);
    final playback = ref.watch(playbackNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: IndexedStack(
        index: navState.currentTab.index,
        children: const [
          LibraryView(),
          SearchView(),
          SettingsView(),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF121212),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Mini Player when song is active
            if (playback.hasCurrentSong) const DynamicMiniPlayer(),

            // Spotify-styled Bottom Navigation Bar
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white10,
                    width: 0.8,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: navState.currentTab.index,
                onTap: (index) {
                  ref
                      .read(navigationNotifierProvider.notifier)
                      .setTab(AppTab.values[index]);
                },
                backgroundColor: const Color(0xFF121212),
                selectedItemColor: const Color(0xFF1DB954),
                unselectedItemColor: Colors.white60,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.library_music_outlined),
                    activeIcon: Icon(Icons.library_music_rounded),
                    label: 'Library',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search_rounded),
                    activeIcon: Icon(Icons.search_rounded),
                    label: 'Search',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    activeIcon: Icon(Icons.settings_rounded),
                    label: 'Settings',
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
