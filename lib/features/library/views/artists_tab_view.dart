import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../playback/playback_provider.dart';
import '../library_provider.dart';
import 'artist_detail_view.dart';

class ArtistsTabView extends ConsumerWidget {
  const ArtistsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final playback = ref.watch(playbackNotifierProvider);

    if (libraryState.isLoading && libraryState.artists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1DB954)),
            SizedBox(height: 16),
            Text(
              'Loading artists...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (libraryState.artists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: Colors.white.withAlpha(80),
              ),
              const SizedBox(height: 16),
              const Text(
                'No artists found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Artists will appear once music tracks are scanned.',
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
            childAspectRatio: 0.85,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: libraryState.artists.length,
          itemBuilder: (context, index) {
            final artist = libraryState.artists[index];
            final artistSongs = ref
                .read(libraryNotifierProvider.notifier)
                .getSongsForArtist(artist.name);
            final songWithArt =
                artistSongs.where((s) => s.artPath != null).firstOrNull;
            final hasArt = songWithArt?.artPath != null &&
                File(songWithArt!.artPath!).existsSync();

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ArtistDetailView(artist: artist),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Spotify circular artist avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF282828),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(80),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: hasArt
                            ? Image.file(
                                File(songWithArt.artPath!),
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: Colors.white38,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${artist.songCount} ${artist.songCount == 1 ? 'track' : 'tracks'} • ${artist.albumCount} ${artist.albumCount == 1 ? 'album' : 'albums'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withAlpha(150),
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
