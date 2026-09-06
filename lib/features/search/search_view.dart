import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/library/song_model.dart';
import '../../widgets/album_art_widget.dart';
import '../../widgets/animated_equalizer.dart';
import '../library/library_provider.dart';
import '../library/views/album_detail_view.dart';
import '../library/views/artist_detail_view.dart';
import '../playback/playback_provider.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds == 0) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final playback = ref.watch(playbackNotifierProvider);

    final cleanQuery = _query.trim().toLowerCase();

    final matchingSongs = cleanQuery.isEmpty
        ? <Song>[]
        : libraryState.songs.where((s) {
            return s.title.toLowerCase().contains(cleanQuery) ||
                s.artist.toLowerCase().contains(cleanQuery) ||
                s.album.toLowerCase().contains(cleanQuery);
          }).toList();

    final matchingAlbums = cleanQuery.isEmpty
        ? []
        : libraryState.albums.where((a) {
            return a.title.toLowerCase().contains(cleanQuery) ||
                a.artist.toLowerCase().contains(cleanQuery);
          }).toList();

    final matchingArtists = cleanQuery.isEmpty
        ? []
        : libraryState.artists.where((art) {
            return art.name.toLowerCase().contains(cleanQuery);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search text box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'What do you want to listen to?',
                hintStyle: TextStyle(color: Colors.black.withAlpha(140)),
                prefixIcon: const Icon(Icons.search, color: Colors.black87),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black54),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() => _query = val);
              },
            ),
          ),

          // Results or Empty State
          Expanded(
            child: cleanQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 64,
                          color: Colors.white.withAlpha(60),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Play what you love',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Search for songs, artists, or albums in your library.',
                          style: TextStyle(color: Colors.white.withAlpha(140)),
                        ),
                      ],
                    ),
                  )
                : (matchingSongs.isEmpty &&
                        matchingAlbums.isEmpty &&
                        matchingArtists.isEmpty)
                    ? Center(
                        child: Text(
                          'No results found for "$_query"',
                          style: TextStyle(
                            color: Colors.white.withAlpha(150),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.only(
                          bottom: playback.hasCurrentSong ? 88 : 24,
                        ),
                        children: [
                          // Matching Artists Section
                          if (matchingArtists.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                'ARTISTS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.white.withAlpha(160),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 110,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: matchingArtists.length,
                                itemBuilder: (context, index) {
                                  final artist = matchingArtists[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ArtistDetailView(artist: artist),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 90,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF282828),
                                            ),
                                            child: const Icon(
                                              Icons.person_rounded,
                                              size: 32,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            artist.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          // Matching Albums Section
                          if (matchingAlbums.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                'ALBUMS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.white.withAlpha(160),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 130,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: matchingAlbums.length,
                                itemBuilder: (context, index) {
                                  final album = matchingAlbums[index];
                                  final hasArt = album.artPath != null &&
                                      File(album.artPath!).existsSync();

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AlbumDetailView(album: album),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 100,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: SizedBox(
                                              width: 80,
                                              height: 80,
                                              child: hasArt
                                                  ? Image.file(
                                                      File(album.artPath!),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      color:
                                                          const Color(0xFF282828),
                                                      child: const Icon(
                                                        Icons.album_rounded,
                                                        color: Colors.white38,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            album.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            album.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  Colors.white.withAlpha(140),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          // Matching Songs Section
                          if (matchingSongs.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                'SONGS (${matchingSongs.length})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.white.withAlpha(160),
                                ),
                              ),
                            ),
                            ...matchingSongs.map((song) {
                              final isCurrent =
                                  playback.currentSong?.id == song.id;
                              final isPlayingThis =
                                  isCurrent && playback.isPlaying;

                              return ListTile(
                                selected: isCurrent,
                                selectedTileColor:
                                    const Color(0xFF1DB954).withAlpha(15),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 2),
                                leading: AlbumArtWidget(
                                  song: song,
                                  size: 44,
                                  borderRadius: 6,
                                  iconSize: 22,
                                ),
                                title: Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isCurrent
                                        ? const Color(0xFF1DB954)
                                        : Colors.white,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${song.artist} • ${song.album}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(140),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPlayingThis) ...[
                                      const AnimatedEqualizer(
                                          isPlaying: true, size: 14),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      _formatDuration(song.duration),
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(140),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  if (isCurrent) {
                                    ref
                                        .read(playbackNotifierProvider.notifier)
                                        .togglePlayPause();
                                  } else {
                                    ref
                                        .read(playbackNotifierProvider.notifier)
                                        .playSong(
                                          song,
                                          playlist: matchingSongs,
                                        );
                                  }
                                },
                              );
                            }),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
