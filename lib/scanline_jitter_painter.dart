// 作用：屏幕过载时的扫描线与水平抖动效果画笔（独立文件，避免类嵌套错误）
import 'dart:math';
import 'package:flutter/material.dart';
import 'game_state.dart';

class ScanlineJitterPainter extends CustomPainter {
  final double strength;
  const ScanlineJitterPainter({required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GameState.getThemeColor().withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 3) {
      final jitter = sin(y / 12) * strength;
      canvas.drawLine(Offset(jitter, y), Offset(size.width + jitter, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ScanlineJitterPainter oldDelegate) => oldDelegate.strength != strength;
}
