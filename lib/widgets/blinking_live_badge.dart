import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/zylo_theme.dart';

class BlinkingLiveBadge extends StatefulWidget {
  final bool isActive;

  const BlinkingLiveBadge({
    super.key,
    required this.isActive,
  });

  @override
  State<BlinkingLiveBadge> createState() => _BlinkingLiveBadgeState();
}

class _BlinkingLiveBadgeState extends State<BlinkingLiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant BlinkingLiveBadge oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final wave = (math.sin(t * math.pi * 2) + 1) / 2; // 0..1
        final opacity = 0.65 + (0.35 * wave);
        final glow = 10 + (8 * wave);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: ZyloColors.zyloYellow.withAlphaF(0.12 * opacity),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: ZyloColors.zyloYellow.withAlphaF(0.55 * opacity)),
            boxShadow: [
              BoxShadow(
                color: ZyloColors.zyloYellow.withAlphaF(0.28 * opacity),
                blurRadius: glow,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: ZyloColors.zyloYellow.withAlphaF(opacity),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ZyloColors.zyloYellow.withAlphaF(0.35 * opacity),
                      blurRadius: glow,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white.withAlpha(opacity > 0.9 ? 255 : 230),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
