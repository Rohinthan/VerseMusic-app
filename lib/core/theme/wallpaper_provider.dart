import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/playback/playback_provider.dart';

/// Predefined wallpaper presets with vibrant aesthetic gradients.
class WallpaperPreset {
  final String id;
  final String name;
  final String description;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;

  const WallpaperPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });
}

const List<WallpaperPreset> kWallpaperPresets = [
  WallpaperPreset(
    id: 'none',
    name: 'Pure Dark',
    description: 'Classic pitch-black theme',
    colors: [Color(0xFF121212), Color(0xFF121212)],
  ),
  WallpaperPreset(
    id: 'dynamic_art',
    name: 'Dynamic Album Art',
    description: 'Blurs the current playing track artwork',
    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
  ),
  WallpaperPreset(
    id: 'cosmic_nebula',
    name: 'Cosmic Nebula',
    description: 'Deep celestial violet and stellar indigo',
    colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
  ),
  WallpaperPreset(
    id: 'cyberpunk_sunset',
    name: 'Cyberpunk Sunset',
    description: 'Neon magenta and electric twilight glow',
    colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2), Color(0xFFFF007F)],
  ),
  WallpaperPreset(
    id: 'midnight_aurora',
    name: 'Midnight Aurora',
    description: 'Emerald and cyan northern lights aura',
    colors: [Color(0xFF051937), Color(0xFF004D7A), Color(0xFF008793), Color(0xFF00BF72)],
  ),
  WallpaperPreset(
    id: 'emerald_obsidian',
    name: 'Emerald Obsidian',
    description: 'Rich dark jade and black mineral tones',
    colors: [Color(0xFF0B1B13), Color(0xFF133826), Color(0xFF09140E)],
  ),
  WallpaperPreset(
    id: 'sunset_horizon',
    name: 'Sunset Horizon',
    description: 'Warm amber, crimson and dusk purple',
    colors: [Color(0xFF2B0938), Color(0xFF6B114D), Color(0xFFB83B5E), Color(0xFFF08A5D)],
  ),
  WallpaperPreset(
    id: 'custom',
    name: 'Custom Image',
    description: 'Use your own image wallpaper from disk',
    colors: [Color(0xFF333333), Color(0xFF555555)],
  ),
];

@immutable
class WallpaperSettings {
  final String presetId;
  final String? customImagePath;
  final double opacity; // 0.0 (transparent) to 1.0 (solid black)
  final double blur; // 0.0 to 30.0
  final double scale; // 0.8 to 1.5

  const WallpaperSettings({
    this.presetId = 'none',
    this.customImagePath,
    this.opacity = 0.65,
    this.blur = 8.0,
    this.scale = 1.0,
  });

  bool get hasActiveWallpaper => presetId != 'none';

  WallpaperSettings copyWith({
    String? presetId,
    String? customImagePath,
    double? opacity,
    double? blur,
    double? scale,
  }) {
    return WallpaperSettings(
      presetId: presetId ?? this.presetId,
      customImagePath: customImagePath ?? this.customImagePath,
      opacity: opacity ?? this.opacity,
      blur: blur ?? this.blur,
      scale: scale ?? this.scale,
    );
  }
}

class WallpaperNotifier extends Notifier<WallpaperSettings> {
  static const String _prefPreset = 'app_wallpaper_preset';
  static const String _prefCustomPath = 'app_wallpaper_custom_path';
  static const String _prefOpacity = 'app_wallpaper_opacity';
  static const String _prefBlur = 'app_wallpaper_blur';
  static const String _prefScale = 'app_wallpaper_scale';

  @override
  WallpaperSettings build() {
    _loadFromPreferences();
    return const WallpaperSettings();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preset = prefs.getString(_prefPreset) ?? 'none';
      final customPath = prefs.getString(_prefCustomPath);
      final opacity = prefs.getDouble(_prefOpacity) ?? 0.65;
      final blur = prefs.getDouble(_prefBlur) ?? 8.0;
      final scale = prefs.getDouble(_prefScale) ?? 1.0;

      state = WallpaperSettings(
        presetId: preset,
        customImagePath: customPath,
        opacity: opacity,
        blur: blur,
        scale: scale,
      );
    } catch (_) {}
  }

  Future<void> setPreset(String presetId) async {
    state = state.copyWith(presetId: presetId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPreset, presetId);
  }

  Future<void> setCustomImagePath(String? path) async {
    state = state.copyWith(presetId: 'custom', customImagePath: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPreset, 'custom');
    if (path != null) {
      await prefs.setString(_prefCustomPath, path);
    } else {
      await prefs.remove(_prefCustomPath);
    }
  }

  Future<void> setOpacity(double opacity) async {
    final clamped = opacity.clamp(0.0, 1.0);
    state = state.copyWith(opacity: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefOpacity, clamped);
  }

  Future<void> setBlur(double blur) async {
    final clamped = blur.clamp(0.0, 30.0);
    state = state.copyWith(blur: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefBlur, clamped);
  }

  Future<void> setScale(double scale) async {
    final clamped = scale.clamp(0.8, 1.6);
    state = state.copyWith(scale: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefScale, clamped);
  }

  Future<void> reset() async {
    state = const WallpaperSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefPreset);
    await prefs.remove(_prefCustomPath);
    await prefs.remove(_prefOpacity);
    await prefs.remove(_prefBlur);
    await prefs.remove(_prefScale);
  }
}

final wallpaperProvider =
    NotifierProvider<WallpaperNotifier, WallpaperSettings>(WallpaperNotifier.new);

/// Wrapper widget that paints the active wallpaper behind the application UI with
/// customizable transparency, blur, and scale.
class WallpaperBackgroundWrapper extends ConsumerWidget {
  final Widget child;

  const WallpaperBackgroundWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaper = ref.watch(wallpaperProvider);

    // If no wallpaper is active, render regular dark background
    if (!wallpaper.hasActiveWallpaper) {
      return Container(
        color: const Color(0xFF121212),
        child: child,
      );
    }

    final playbackState = ref.watch(playbackNotifierProvider);
    final currentSong = playbackState.currentSong;

    Widget wallpaperBackground;

    if (wallpaper.presetId == 'custom' &&
        wallpaper.customImagePath != null &&
        File(wallpaper.customImagePath!).existsSync()) {
      wallpaperBackground = Transform.scale(
        scale: wallpaper.scale,
        child: Image.file(
          File(wallpaper.customImagePath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (wallpaper.presetId == 'dynamic_art' &&
        currentSong?.artPath != null &&
        File(currentSong!.artPath!).existsSync()) {
      wallpaperBackground = Transform.scale(
        scale: wallpaper.scale,
        child: Image.file(
          File(currentSong.artPath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else {
      // Find preset or fallback
      final preset = kWallpaperPresets.firstWhere(
        (p) => p.id == wallpaper.presetId,
        orElse: () => kWallpaperPresets[2], // cosmic_nebula
      );

      wallpaperBackground = Transform.scale(
        scale: wallpaper.scale,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: preset.begin,
              end: preset.end,
              colors: preset.colors,
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Wallpaper image / gradient
        wallpaperBackground,

        // 2. Blur Filter
        if (wallpaper.blur > 0)
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: wallpaper.blur,
              sigmaY: wallpaper.blur,
            ),
            child: const SizedBox.expand(),
          ),

        // 3. User adjustable dark overlay for content legibility
        Container(
          color: Color.fromRGBO(18, 18, 18, wallpaper.opacity),
        ),

        // 4. Foreground UI
        child,
      ],
    );
  }
}
