import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/library/library_provider.dart';
import '../../features/playback/playback_provider.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final playback = ref.watch(playbackNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: playback.hasCurrentSong ? 96 : 24,
        ),
        children: [
          // Library & Storage Section
          _buildSectionHeader('LIBRARY & STORAGE'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_outlined, color: Color(0xFF1DB954)),
                  title: const Text('Music Directories', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    Platform.isLinux
                        ? '~/Music (default) & custom folders'
                        : 'Android MediaStore (Audio)',
                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  ),
                ),
                const Divider(height: 1, indent: 56, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.storage_rounded, color: Color(0xFF1DB954)),
                  title: const Text('Indexed Library Stats', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    '${libraryState.songs.length} tracks • ${libraryState.albums.length} albums • ${libraryState.artists.length} artists',
                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  ),
                ),
                const Divider(height: 1, indent: 56, color: Colors.white10),
                ListTile(
                  leading: libraryState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1DB954),
                          ),
                        )
                      : const Icon(Icons.sync_rounded, color: Color(0xFF1DB954)),
                  title: const Text('Rescan Music Library', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    libraryState.isLoading ? 'Scanning files...' : 'Tap to scan for new or modified songs',
                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: libraryState.isLoading
                        ? null
                        : () => ref.read(libraryNotifierProvider.notifier).scan(),
                    child: const Text('Scan Now'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Audio Engine Section
          _buildSectionHeader('AUDIO ENGINE & HARDWARE'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.album_outlined, color: Color(0xFF1DB954)),
                  title: const Text('Platform Backend', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    Platform.isLinux
                        ? 'just_audio_media_kit (libmpv native backend)'
                        : 'audio_service (Android MediaSession & AudioTrack)',
                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  ),
                ),
                const Divider(height: 1, indent: 56, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.volume_up_rounded, color: Color(0xFF1DB954)),
                  title: const Text('Equalizer & Audio Output', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    'High-fidelity hardware output • Active',
                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('ABOUT VERSE'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.graphic_eq_rounded, color: Colors.black, size: 20),
                  ),
                  title: const Text('Verse Music Player', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Version v0.4 • Spotify-like Shell UI', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                const Divider(height: 1, indent: 56, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.code_rounded, color: Colors.white70),
                  title: const Text('GitHub Repository', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text(
                    'Rohinthan/VerseMusic-app',
                    style: TextStyle(color: Color(0xFF1DB954), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.white.withAlpha(160),
        ),
      ),
    );
  }
}
