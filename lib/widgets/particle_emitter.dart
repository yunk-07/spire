// 作用：轻量粒子发射器，用于命中/护盾破裂等瞬时粒子效果
import 'dart:math';
import 'package:flutter/material.dart';

class ParticleBurst extends StatefulWidget {
  final Offset center;
  final int count;
  final Color color;
  final Duration duration;

  const ParticleBurst({
    super.key,
    required this.center,
    required this.count,
    required this.color,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Stack(
          children: List.generate(widget.count, (i) {
            final angle = (i / widget.count) * pi * 2;
            final dist = Curves.easeOut.transform(t) * 80;
            final size = (1.0 - t) * 6;
            return Positioned(
              left: widget.center.dx + cos(angle) * dist,
              top: widget.center.dy + sin(angle) * dist,
              child: Opacity(
                opacity: (1.0 - t).clamp(0.0, 1.0),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
