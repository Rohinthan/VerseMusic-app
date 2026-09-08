import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../navigation/navigation_provider.dart';
import '../library_provider.dart';
import 'albums_tab_view.dart';
import 'artists_tab_view.dart';
import 'songs_tab_view.dart';

class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final navState = ref.watch(navigationNotifierProvider);
    final accentColor = ref.watch(accentColorProvider);
    final isBright = ThemeData.estimateBrightnessForColor(accentColor) == Brightness.light;
    final onAccent = isBright ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.graphic_eq_rounded,
                color: onAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verse Library',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  Platform.isLinux ? 'Linux Desktop' : 'Android Audio',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withAlpha(150),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: libraryState.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan Library',
            onPressed: libraryState.isLoading
                ? null
                : () => ref.read(libraryNotifierProvider.notifier).scan(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPillTab(
                    context: context,
                    ref: ref,
                    title: 'Songs',
                    count: libraryState.songs.length,
                    tab: LibraryTab.songs,
                    isSelected: navState.libraryTab == LibraryTab.songs,
                    accentColor: accentColor,
                    onAccent: onAccent,
                  ),
                  const SizedBox(width: 8),
                  _buildPillTab(
                    context: context,
                    ref: ref,
                    title: 'Albums',
                    count: libraryState.albums.length,
                    tab: LibraryTab.albums,
                    isSelected: navState.libraryTab == LibraryTab.albums,
                    accentColor: accentColor,
                    onAccent: onAccent,
                  ),
                  const SizedBox(width: 8),
                  _buildPillTab(
                    context: context,
                    ref: ref,
                    title: 'Artists',
                    count: libraryState.artists.length,
                    tab: LibraryTab.artists,
                    isSelected: navState.libraryTab == LibraryTab.artists,
                    accentColor: accentColor,
                    onAccent: onAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: navState.libraryTab.index,
        children: const [
          SongsTabView(),
          AlbumsTabView(),
          ArtistsTabView(),
        ],
      ),
    );
  }

  Widget _buildPillTab({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required int count,
    required LibraryTab tab,
    required bool isSelected,
    required Color accentColor,
    required Color onAccent,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(navigationNotifierProvider.notifier).setLibraryTab(tab);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor
              : const Color(0xFF282828),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? onAccent : Colors.white,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? onAccent.withAlpha(35)
                      : Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? onAccent : Colors.white70,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
