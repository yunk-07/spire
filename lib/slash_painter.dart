// 作用：斩击特效的自定义画笔，绘制弧形斩击痕迹、多层尾迹与核心闪光
import 'dart:math';
import 'package:flutter/material.dart';

class SlashPainter extends CustomPainter {
  final Offset center;
  final double progress;
  final Color color;

  SlashPainter({
    required this.center,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final t = progress.clamp(0.0, 1.0);
    final alpha = (1.0 - t);
    final baseWidth = 6.0 * alpha;
    final radius = 120.0;
    final angle = (-pi / 6) + (pi / 3) * Curves.easeOut.transform(t);

    // 构造弧形路径（二次贝塞尔）
    Path buildArc(Offset c, double r, double a, double bend) {
      final dir = Offset(cos(a), sin(a));
      final normal = Offset(-dir.dy, dir.dx);
      final start = c - dir * r * 0.6 - normal * r * 0.15;
      final end = c + dir * r * 0.6 + normal * r * 0.05;
      final ctrl = c + normal * r * bend;
      final p = Path()..moveTo(start.dx, start.dy)..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      return p;
    }

    // 光晕层
    final glow = Paint()
      ..color = color.withValues(alpha: alpha * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth * 2.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // 主体层
    final stroke = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth
      ..strokeCap = StrokeCap.round;

    // 核心白光
    final core = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth * 0.45
      ..strokeCap = StrokeCap.round;

    // 主斩击
    final bend = 0.25 + 0.15 * (1.0 - alpha);
    final arc = buildArc(center, radius, angle, bend);
    canvas.drawPath(arc, glow);
    canvas.drawPath(arc, stroke);
    canvas.drawPath(arc, core);

    // 尾迹层（多重残影）
    for (int i = 1; i <= 3; i++) {
      final trailAlpha = (alpha * (0.6 - i * 0.15)).clamp(0.0, 1.0);
      if (trailAlpha <= 0) continue;
      final trail = Paint()
        ..color = color.withValues(alpha: trailAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseWidth * (1.0 - i * 0.15)
        ..strokeCap = StrokeCap.round;
      final offset = Offset(-sin(angle), cos(angle)) * (i * 6.0);
      final arcTrail = buildArc(center + offset, radius * (1.0 - i * 0.06), angle, bend * (1.0 - i * 0.1));
      canvas.drawPath(arcTrail, trail);
    }
  }

  @override
  bool shouldRepaint(covariant SlashPainter oldDelegate) => true;
}
