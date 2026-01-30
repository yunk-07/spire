import 'package:flutter/material.dart';
import '../game_state.dart';
// import 'dart:math' as math;

class HoloTowerWidget extends StatefulWidget {
  const HoloTowerWidget({super.key});
  @override
  State<HoloTowerWidget> createState() => _HoloTowerWidgetState();
}

class _HoloTowerWidgetState extends State<HoloTowerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
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
      builder: (_, __) {
        return CustomPaint(
          painter: _HoloTowerPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _HoloTowerPainter extends CustomPainter {
  final double progress;
  _HoloTowerPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height * 0.8;
    final towerHeight = size.height * 0.55;
    final towerWidthBase = size.width * 0.12;
    final towerTopY = baseY - towerHeight;

    final ringCount = 6;
    for (int i = 0; i < ringCount; i++) {
      final p = ((progress + i / ringCount) % 1.0);
      final alpha = (1.0 - p) * 0.25;
      final radius = towerWidthBase * 1.2 + p * size.width * 0.25;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = GameState.getThemeColor().withValues(alpha: alpha);
      canvas.drawCircle(Offset(centerX, towerTopY + towerHeight * 0.2), radius, ringPaint);
    }

  }
  @override
  bool shouldRepaint(covariant _HoloTowerPainter oldDelegate) => true;
}
