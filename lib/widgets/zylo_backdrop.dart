import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/zylo_theme.dart';

class ZyloBackdrop extends StatefulWidget {
  final double intensity;

  const ZyloBackdrop({
    super.key,
    this.intensity = 1,
  });

  @override
  State<ZyloBackdrop> createState() => _ZyloBackdropState();
}

class _ZyloBackdropState extends State<ZyloBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = widget.intensity < 0 ? 0.0 : (widget.intensity > 1 ? 1.0 : widget.intensity);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final wobble = (math.sin(t * math.pi * 2) + 1) / 2; // 0..1
          final center = Alignment.lerp(const Alignment(-0.55, -0.9), const Alignment(0.65, -0.35), wobble)!;

          return Container(
            decoration: BoxDecoration(
              color: ZyloColors.black,
              gradient: RadialGradient(
                center: center,
                radius: 1.15,
                colors: [
                  ZyloColors.electricBlue.withAlphaF(0.16 * intensity),
                  ZyloColors.zyloYellow.withAlphaF(0.08 * intensity),
                  ZyloColors.neonGreen.withAlphaF(0.06 * intensity),
                  ZyloColors.black,
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-1, -1),
                  end: const Alignment(1, 1),
                  colors: [
                    ZyloColors.zyloYellow.withAlphaF(0.05 * intensity),
                    ZyloColors.black.withAlphaF(0.0),
                    ZyloColors.electricBlue.withAlphaF(0.04 * intensity),
                  ],
                  stops: [0.0, 0.55 + (wobble * 0.12), 1.0],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
