import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedEqualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double size;

  const AnimatedEqualizer({
    super.key,
    required this.isPlaying,
    this.color = const Color(0xFF1DB954),
    this.size = 18.0,
  });

  @override
  State<AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<AnimatedEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AnimatedEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // 3 bars with staggered sinusoidal phases
        final h1 = widget.isPlaying ? (0.3 + 0.7 * math.sin(t * math.pi)).clamp(0.2, 1.0) : 0.2;
        final h2 = widget.isPlaying ? (0.2 + 0.8 * math.sin((t + 0.3) * math.pi)).clamp(0.2, 1.0) : 0.4;
        final h3 = widget.isPlaying ? (0.4 + 0.6 * math.sin((t + 0.6) * math.pi)).clamp(0.2, 1.0) : 0.2;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(h1),
              _buildBar(h2),
              _buildBar(h3),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(double heightFraction) {
    final barWidth = widget.size / 5.0;
    return Container(
      width: barWidth,
      height: widget.size * heightFraction,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(barWidth / 2),
      ),
    );
  }
}
