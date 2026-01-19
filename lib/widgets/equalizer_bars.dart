import 'dart:math' as math;

import 'package:flutter/material.dart';

class EqualizerBars extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double height;
  final int bars;

  const EqualizerBars({
    super.key,
    required this.isActive,
    required this.color,
    this.height = 14,
    this.bars = 5,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _barValue(int index, double t) {
    // Stable pseudo-random phases per bar for a simple equalizer vibe.
    final phase = (index + 1) * 0.9;
    final v = (math.sin((t * math.pi * 2) + phase) + 1) / 2; // 0..1
    final shaped = 0.25 + (v * 0.75);
    return shaped;
  }

  @override
  Widget build(BuildContext context) {
    final bars = widget.bars.clamp(3, 7);
    final glowColor = widget.color.withValues(alpha: 0.22);

    return SizedBox(
      height: widget.height,
      child: TickerMode(
        enabled: widget.isActive,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(bars, (i) {
                final v = widget.isActive ? _barValue(i, t) : 0.22;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    width: 3,
                    height: widget.height * v,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: widget.isActive
                          ? [
                              BoxShadow(
                                color: glowColor,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
