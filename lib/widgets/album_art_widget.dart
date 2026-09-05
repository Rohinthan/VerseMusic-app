import 'dart:io';
import 'package:flutter/material.dart';
import '../core/library/song_model.dart';

class AlbumArtWidget extends StatelessWidget {
  final Song song;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;
  final double iconSize;

  const AlbumArtWidget({
    super.key,
    required this.song,
    this.size = 48.0,
    this.borderRadius = 8.0,
    this.fallbackIcon = Icons.music_note_rounded,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget? imageContent;

    if (song.artPath != null) {
      final file = File(song.artPath!);
      if (file.existsSync()) {
        imageContent = Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        );
      }
    }

    if (imageContent == null && song.embeddedArt != null) {
      imageContent = Image.memory(
        song.embeddedArt!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF242424),
        child: imageContent ?? _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Icon(
        fallbackIcon,
        color: Colors.white24,
        size: iconSize,
      ),
    );
  }
}
