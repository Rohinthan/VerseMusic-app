import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/album_art_widget.dart';
import '../../playback/playback_provider.dart';
import '../library_provider.dart';
import 'album_detail_view.dart';

class AlbumsTabView extends ConsumerWidget {
  const AlbumsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final playback = ref.watch(playbackNotifierProvider);

    if (libraryState.isLoading && libraryState.albums.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1DB954)),
            SizedBox(height: 16),
            Text(
              'Loading albums...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (libraryState.albums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.album_outlined,
                size: 64,
                color: Colors.white.withAlpha(80),
              ),
              const SizedBox(height: 16),
              const Text(
                'No albums found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Audio files will be automatically grouped into albums.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withAlpha(160)),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

        return GridView.builder(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: playback.hasCurrentSong ? 96 : 24,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.78,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: libraryState.albums.length,
          itemBuilder: (context, index) {
            final album = libraryState.albums[index];
            final hasArt =
                album.artPath != null && File(album.artPath!).existsSync();

            // If album has no direct artPath, check if any of its songs has art
            final albumSongs = ref
                .read(libraryNotifierProvider.notifier)
                .getSongsForAlbum(album.title);
            final fallbackSong =
                albumSongs.where((s) => s.artPath != null).firstOrNull;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AlbumDetailView(album: album),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withAlpha(10),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Album Cover Image
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: double.infinity,
                          child: hasArt
                              ? Image.file(
                                  File(album.artPath!),
                                  fit: BoxFit.cover,
                                )
                              : (fallbackSong != null
                                  ? AlbumArtWidget(
                                      song: fallbackSong,
                                      size: double.infinity,
                                    )
                                  : Container(
                                      color: const Color(0xFF242424),
                                      child: const Icon(
                                        Icons.album_rounded,
                                        size: 48,
                                        color: Colors.white24,
                                      ),
                                    )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Album Title
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Artist
                    Text(
                      album.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Track count badge
                    Text(
                      '${album.songCount} ${album.songCount == 1 ? 'song' : 'songs'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1DB954),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
