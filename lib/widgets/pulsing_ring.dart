import 'dart:math' as math;

import 'package:flutter/material.dart';

class PulsingRing extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double size;
  final Widget child;

  const PulsingRing({
    super.key,
    required this.isActive,
    required this.color,
    required this.size,
    required this.child,
  });

  @override
  State<PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<PulsingRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PulsingRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
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
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final p = (math.sin(t * math.pi * 2) + 1) / 2; // 0..1
        final scale = 1.0 + (p * 0.08);
        final opacity = 0.22 + ((1 - p) * 0.18);

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size + 18,
                height: widget.size + 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color.withValues(alpha: opacity), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: opacity * 0.65),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}
