import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/wallpaper_provider.dart';
import '../../core/window/window_service.dart';
import '../library/library_provider.dart';
import '../playback/playback_provider.dart';
import 'settings_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  void _showCustomWallpaperDialog() {
    final textController = TextEditingController(
      text: ref.read(wallpaperProvider).customImagePath ?? '',
    );
    final accentColor = ref.read(accentColorProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text('Custom Wallpaper Image', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the absolute path of an image file (PNG, JPG, WEBP) on your computer:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '/home/user/Pictures/wallpaper.jpg',
                hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                filled: true,
                fillColor: const Color(0xFF181818),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final path = textController.text.trim();
              if (path.isNotEmpty) {
                if (File(path).existsSync()) {
                  ref.read(wallpaperProvider.notifier).setCustomImagePath(path);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Applied custom wallpaper: $path'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File not found. Please verify the absolute path.'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text('Apply Wallpaper', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddDirectoryDialog() {
    final textController = TextEditingController();
    final accentColor = ref.read(accentColorProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text('Add Music Directory', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the absolute path of a folder containing audio files:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '/home/user/Music/Albums',
                hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                filled: true,
                fillColor: const Color(0xFF181818),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final path = textController.text.trim();
              if (path.isNotEmpty) {
                ref.read(libraryNotifierProvider.notifier).addDirectory(path);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added directory: $path'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Add & Scan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmClearLyricsCache() {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        final dialogNavigator = Navigator.of(ctx);
        return AlertDialog(
          backgroundColor: const Color(0xFF242424),
          title: const Text('Clear Lyrics Cache?', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: const Text(
            'This will delete all locally cached LRCLIB lyrics from the database. Local .lrc files on disk will not be affected.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => dialogNavigator.pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await ref.read(settingsServiceProvider).clearLyricsCache();
                if (mounted) {
                  dialogNavigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Lyrics cache cleared successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Clear Cache', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryNotifierProvider);
    final playback = ref.watch(playbackNotifierProvider);
    final accentColor = ref.watch(accentColorProvider);
    final isOnlineLyricsEnabled = ref.watch(lyricsOnlineFetchProvider);
    final wallpaper = ref.watch(wallpaperProvider);

    final activeColorOption = kAccentColors.firstWhere(
      (c) => c.color.toARGB32() == accentColor.toARGB32(),
      orElse: () => kAccentColors.first,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
          // Theme & Appearance Section (14 Color Options)
          _buildSectionHeader('APPEARANCE & THEME'),
          Material(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: accentColor, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Accent Color',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentColor.withAlpha(80)),
                        ),
                        child: Text(
                          activeColorOption.name,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: kAccentColors.map((option) {
                      final isSelected = option.color.toARGB32() == accentColor.toARGB32();

                      return Tooltip(
                        message: option.name,
                        child: InkWell(
                          onTap: () {
                            ref.read(accentColorProvider.notifier).setAccentColor(option.color);
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: option.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: option.color.withAlpha(140),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 22)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Wallpaper & Transparency Section
          _buildSectionHeader('BACKGROUND WALLPAPER & TRANSPARENCY'),
          Material(
            color: const Color(0xE6181818),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wallpaper_rounded, color: accentColor, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Wallpaper Style',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentColor.withAlpha(80)),
                        ),
                        child: Text(
                          kWallpaperPresets.firstWhere(
                            (p) => p.id == wallpaper.presetId,
                            orElse: () => kWallpaperPresets.first,
                          ).name,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select a curated gradient aura, dynamic album art, or custom image:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Preset Tiles
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: kWallpaperPresets.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final preset = kWallpaperPresets[index];
                        final isSelected = wallpaper.presetId == preset.id;

                        return InkWell(
                          onTap: () {
                            if (preset.id == 'custom') {
                              _showCustomWallpaperDialog();
                            } else {
                              ref.read(wallpaperProvider.notifier).setPreset(preset.id);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 104,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: preset.begin,
                                end: preset.end,
                                colors: preset.colors,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? accentColor : Colors.white24,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: accentColor.withAlpha(100),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Text(
                                    preset.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      shadows: const [
                                        Shadow(color: Colors.black87, blurRadius: 4),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (wallpaper.presetId == 'custom') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            wallpaper.customImagePath ?? 'No image selected',
                            style: TextStyle(
                              color: Colors.white.withAlpha(160),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text('Change Path', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: accentColor),
                          onPressed: _showCustomWallpaperDialog,
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),

                  // Overlay Transparency Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.opacity_rounded, color: accentColor, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Dark Overlay Opacity',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        '${(wallpaper.opacity * 100).toInt()}%',
                        style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: wallpaper.opacity,
                    min: 0.10,
                    max: 0.95,
                    divisions: 85,
                    activeColor: accentColor,
                    inactiveColor: Colors.white12,
                    onChanged: (val) => ref.read(wallpaperProvider.notifier).setOpacity(val),
                  ),
                  Text(
                    'Lower values make the background wallpaper more visible; higher values improve text contrast.',
                    style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11),
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),

                  // Blur Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.blur_on_rounded, color: accentColor, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Background Blur',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        '${wallpaper.blur.toStringAsFixed(1)} px',
                        style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: wallpaper.blur,
                    min: 0.0,
                    max: 25.0,
                    divisions: 50,
                    activeColor: accentColor,
                    inactiveColor: Colors.white12,
                    onChanged: (val) => ref.read(wallpaperProvider.notifier).setBlur(val),
                  ),
                  Text(
                    'Smooth out high-frequency wallpaper details with a frosted glass look.',
                    style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11),
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),

                  // Scale Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.aspect_ratio_rounded, color: accentColor, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Wallpaper Zoom & Size',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        '${wallpaper.scale.toStringAsFixed(2)}x',
                        style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: wallpaper.scale,
                    min: 0.80,
                    max: 1.50,
                    divisions: 70,
                    activeColor: accentColor,
                    inactiveColor: Colors.white12,
                    onChanged: (val) => ref.read(wallpaperProvider.notifier).setScale(val),
                  ),
                  Text(
                    'Scale and stretch the wallpaper background to suit your screen dimensions.',
                    style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11),
                  ),

                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.white60),
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text('Reset Wallpaper Settings', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        ref.read(wallpaperProvider.notifier).reset();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wallpaper settings reset to default'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Library & Storage Section
          _buildSectionHeader('LIBRARY & STORAGE'),
          Material(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.folder_outlined, color: accentColor),
                  title: const Text('Music Directories', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    libraryState.directories.isEmpty
                        ? (Platform.isLinux ? '~/Music (default)' : 'Android MediaStore')
                        : libraryState.directories.join('\n'),
                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  ),
                  trailing: Platform.isLinux
                      ? IconButton(
                          icon: Icon(Icons.add_circle_outline_rounded, color: accentColor),
                          onPressed: _showAddDirectoryDialog,
                          tooltip: 'Add Custom Folder',
                        )
                      : null,
                ),
                if (libraryState.directories.isNotEmpty && Platform.isLinux) ...[
                  ...libraryState.directories.map((dir) => ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 56, right: 16),
                        title: Text(dir, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.white38),
                          onPressed: () {
                            ref.read(libraryNotifierProvider.notifier).removeDirectory(dir);
                          },
                        ),
                      )),
                ],
                const Divider(height: 1, indent: 56, color: Colors.white10),
                ListTile(
                  leading: Icon(Icons.storage_rounded, color: accentColor),
                  title: const Text('Indexed Library Stats', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    '${libraryState.songs.length} tracks • ${libraryState.albums.length} albums • ${libraryState.artists.length} artists',
                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  ),
                ),
                const Divider(height: 1, indent: 56, color: Colors.white10),
                ListTile(
                  leading: libraryState.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        )
                      : Icon(Icons.sync_rounded, color: accentColor),
                  title: const Text('Rescan Music Library', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    libraryState.isLoading ? 'Scanning files...' : 'Tap to scan for new or modified songs',
                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
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

          // Lyrics & Metadata Section
          _buildSectionHeader('LYRICS & METADATA'),
          Material(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  activeThumbColor: Colors.white,
                  activeTrackColor: accentColor,
                  secondary: Icon(Icons.lyrics_outlined, color: accentColor),
                  title: const Text('Fetch Online Lyrics (LRCLIB)', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    'Automatically look up synced lyrics if no local .lrc file is found',
                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  ),
                  value: isOnlineLyricsEnabled,
                  onChanged: (val) {
                    ref.read(lyricsOnlineFetchProvider.notifier).toggle(val);
                  },
                ),
                const Divider(height: 1, indent: 56, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: Colors.white70),
                  title: const Text('Clear Lyrics Cache', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    'Delete locally cached lyrics stored in SQLite database',
                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  ),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withAlpha(50)),
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: _confirmClearLyricsCache,
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Audio Engine Section
          _buildSectionHeader('AUDIO ENGINE & HARDWARE'),
          Material(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.album_outlined, color: accentColor),
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
                  leading: Icon(Icons.volume_up_rounded, color: accentColor),
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

          // Notifications & Pop-up Window Section
          _buildSectionHeader('NOTIFICATIONS & POPUP WINDOW'),
          Material(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.notifications_active_outlined, color: accentColor),
                  activeTrackColor: accentColor,
                  thumbColor: const WidgetStatePropertyAll(Colors.white),
                  title: const Text('Desktop Song Notifications', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    'Show a notification popup at the top when changing songs',
                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  ),
                  value: ref.watch(desktopNotificationEnabledProvider),
                  onChanged: (val) {
                    ref.read(desktopNotificationEnabledProvider.notifier).toggle(val);
                  },
                ),
                const Divider(height: 1, indent: 56, color: Colors.white10),
                ListTile(
                  leading: Icon(Icons.menu_open_rounded, color: accentColor),
                  title: const Text('Top Bar Notification Menu', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    Platform.isLinux
                        ? 'MPRIS D-Bus integration • Control & change songs from top menu'
                        : 'Android MediaSession notification • Control & change songs',
                    style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Active', style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (WindowService.isDesktop) ...[
                  const Divider(height: 1, indent: 56, color: Colors.white10),
                  ListTile(
                    leading: Icon(Icons.picture_in_picture_alt_rounded, color: accentColor),
                    title: const Text('Floating Pop Window Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text(
                      'Compact always-on-top mini player window to change songs while using other apps',
                      style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                    ),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor.withAlpha(120)),
                        foregroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () => WindowService.enterMiniWindowMode(ref),
                      child: const Text('Launch', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('ABOUT VERSE'),
          Material(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.graphic_eq_rounded, color: Colors.black, size: 20),
                  ),
                  title: const Text('Verse Music Player', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Version v0.8 • Search & Settings', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                const Divider(height: 1, indent: 56, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.code_rounded, color: Colors.white70),
                  title: const Text('GitHub Repository', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    'Rohinthan/VerseMusic-app',
                    style: TextStyle(color: accentColor, fontSize: 12),
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
