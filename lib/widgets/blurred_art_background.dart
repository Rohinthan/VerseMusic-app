import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/library/song_model.dart';

/// Ambient blurred background widget for Now Playing and detail views.
/// Renders an atmospheric blurred version of the song's album art with
/// smooth dark vignette overlays for readability.
class BlurredArtBackground extends StatelessWidget {
  final Song? song;
  final Widget child;
  final double blurSigma;

  const BlurredArtBackground({
    super.key,
    required this.song,
    required this.child,
    this.blurSigma = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    final artPath = song?.artPath;
    final hasArt = artPath != null && File(artPath).existsSync();

    return Stack(
      children: [
        // Base dark background
        const Positioned.fill(
          child: ColoredBox(color: Color(0xFF121212)),
        ),

        // Blurred Artwork Layer
        if (hasArt)
          Positioned.fill(
            child: ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                  tileMode: TileMode.mirror,
                ),
                child: Transform.scale(
                  scale: 1.3, // Scale up slightly to prevent blur edge bleeding
                  child: Image.file(
                    File(artPath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          )
        else
          // Ambient Fallback Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E3A2B), // Subtle Spotify forest green hue
                    Color(0xFF16201B),
                    Color(0xFF121212),
                  ],
                ),
              ),
            ),
          ),

        // Dark Vignette & Readability Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(140),
                  Colors.black.withAlpha(160),
                  Colors.black.withAlpha(220),
                  const Color(0xFF121212).withAlpha(245),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Foreground Content
        Positioned.fill(child: child),
      ],
    );
  }
}
