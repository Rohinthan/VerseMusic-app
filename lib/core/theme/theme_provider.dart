import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AccentColorOption {
  final String id;
  final String name;
  final Color color;

  const AccentColorOption({
    required this.id,
    required this.name,
    required this.color,
  });
}

/// 24 distinct, vibrant accent color options for personalized UI theming.
const List<AccentColorOption> kAccentColors = [
  AccentColorOption(
    id: 'spotify_green',
    name: 'Spotify Green',
    color: Color(0xFF1DB954),
  ),
  AccentColorOption(
    id: 'emerald_mint',
    name: 'Emerald Mint',
    color: Color(0xFF00D26A),
  ),
  AccentColorOption(
    id: 'electric_cyan',
    name: 'Electric Cyan',
    color: Color(0xFF00E5FF),
  ),
  AccentColorOption(
    id: 'deep_sky_blue',
    name: 'Sky Blue',
    color: Color(0xFF2979FF),
  ),
  AccentColorOption(
    id: 'royal_purple',
    name: 'Royal Purple',
    color: Color(0xFF7C4DFF),
  ),
  AccentColorOption(
    id: 'neon_violet',
    name: 'Neon Violet',
    color: Color(0xFFB388FF),
  ),
  AccentColorOption(
    id: 'magenta_pink',
    name: 'Magenta Pink',
    color: Color(0xFFFF4081),
  ),
  AccentColorOption(
    id: 'crimson_red',
    name: 'Crimson Red',
    color: Color(0xFFFF1744),
  ),
  AccentColorOption(
    id: 'sunset_orange',
    name: 'Sunset Orange',
    color: Color(0xFFFF6D00),
  ),
  AccentColorOption(
    id: 'amber_gold',
    name: 'Amber Gold',
    color: Color(0xFFFFD600),
  ),
  AccentColorOption(
    id: 'electric_lime',
    name: 'Electric Lime',
    color: Color(0xFF76FF03),
  ),
  AccentColorOption(
    id: 'neon_coral',
    name: 'Neon Coral',
    color: Color(0xFFFF6E40),
  ),
  AccentColorOption(
    id: 'aqua_teal',
    name: 'Aqua Teal',
    color: Color(0xFF1DE9B6),
  ),
  AccentColorOption(
    id: 'orchid_plum',
    name: 'Orchid Plum',
    color: Color(0xFFE040FB),
  ),
  AccentColorOption(
    id: 'rose_gold',
    name: 'Rose Gold',
    color: Color(0xFFF06292),
  ),
  AccentColorOption(
    id: 'cyberpunk_yellow',
    name: 'Cyberpunk Yellow',
    color: Color(0xFFEEFF41),
  ),
  AccentColorOption(
    id: 'lavender_mist',
    name: 'Lavender Mist',
    color: Color(0xFFBA68C8),
  ),
  AccentColorOption(
    id: 'sapphire_blue',
    name: 'Sapphire Blue',
    color: Color(0xFF3D5AFE),
  ),
  AccentColorOption(
    id: 'peach_blossom',
    name: 'Peach Blossom',
    color: Color(0xFFFF8A65),
  ),
  AccentColorOption(
    id: 'emerald_forest',
    name: 'Emerald Forest',
    color: Color(0xFF00BFA5),
  ),
  AccentColorOption(
    id: 'flame_orange',
    name: 'Flame Orange',
    color: Color(0xFFFF3D00),
  ),
  AccentColorOption(
    id: 'ruby_cherry',
    name: 'Ruby Cherry',
    color: Color(0xFFD50000),
  ),
  AccentColorOption(
    id: 'neon_ice',
    name: 'Ice Cyan',
    color: Color(0xFF18FFFF),
  ),
  AccentColorOption(
    id: 'golden_honey',
    name: 'Golden Honey',
    color: Color(0xFFFFAB00),
  ),
];

class AccentColorNotifier extends Notifier<Color> {
  static const String _prefKey = 'app_accent_color_val';

  @override
  Color build() {
    _loadFromPreferences();
    return const Color(0xFF1DB954); // Default to Spotify Green
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getInt(_prefKey);
      if (savedValue != null) {
        state = Color(savedValue);
      }
    } catch (_) {}
  }

  Future<void> setAccentColor(Color color) async {
    state = color;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey, color.toARGB32());
    } catch (_) {}
  }
}

final accentColorProvider =
    NotifierProvider<AccentColorNotifier, Color>(AccentColorNotifier.new);
