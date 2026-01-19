import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/zylo_theme.dart';

class AnimatedCoverArt extends StatefulWidget {
  final Widget child;
  final bool isPlaying;
  final double size;
  final BorderRadius borderRadius;

  const AnimatedCoverArt({
    super.key,
    required this.child,
    required this.isPlaying,
    required this.size,
    required this.borderRadius,
  });

  @override
  State<AnimatedCoverArt> createState() => _AnimatedCoverArtState();
}

class _AnimatedCoverArtState extends State<AnimatedCoverArt> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCoverArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final wave = (math.sin(t * math.pi * 2) + 1) / 2; // 0..1
          final scale = widget.isPlaying ? (1.0 + (0.03 * wave)) : 1.0;
          final blurSigma = widget.isPlaying ? (1.2 + (0.6 * wave)) : 0.0;

          return Transform.scale(
            scale: scale,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.isPlaying)
                  Opacity(
                    opacity: 0.30,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: widget.borderRadius,
                          boxShadow: ZyloFx.glow(ZyloColors.zyloYellow, blur: 26),
                        ),
                        child: ClipRRect(
                          borderRadius: widget.borderRadius,
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ClipRRect(
                  borderRadius: widget.borderRadius,
                  child: widget.child,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
