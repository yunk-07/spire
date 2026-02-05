import 'package:flutter/material.dart';
import '../config/theme_config.dart';

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
          painter: CyberHoloTowerPainter(progress: _controller.value),
        );
      },
    );
  }
}
