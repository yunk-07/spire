// 作用：激光特效的自定义画笔，提供核心亮线与外沿光晕绘制
import 'package:flutter/material.dart';

class LaserPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;
  final Color color;
  final double width;
  final double opacity;

  LaserPainter({
    required this.start,
    required this.end,
    required this.progress,
    required this.color,
    required this.width,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.3)
      ..strokeWidth = width * 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, glowPaint);
    canvas.drawLine(start, end, paint);

    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = width * 0.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, corePaint);
  }

  @override
  bool shouldRepaint(covariant LaserPainter oldDelegate) => true;
}
