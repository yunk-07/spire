import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Holo Grid Animation Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AnimationTestPage(),
    );
  }
}

class AnimationTestPage extends StatefulWidget {
  const AnimationTestPage({super.key});

  @override
  State<AnimationTestPage> createState() => _AnimationTestPageState();
}

class _AnimationTestPageState extends State<AnimationTestPage> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        title: const Text('Holo Grid Animation Test'),
        backgroundColor: const Color(0xFF0C1018),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2332),
                border: Border.all(color: const Color(0xFF6CE4FF), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Text(
                      'Test Character',
                      style: TextStyle(
                        color: Color(0xFF6CE4FF),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _HoloGridPainter(progress: _controller.value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _controller.forward(from: 0);
              },
              child: const Text('Start Animation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoloGridPainter extends CustomPainter {
  final double progress;

  const _HoloGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.05) {
      return;
    }
    final p = progress.clamp(0.0, 1.0);

    double regionLeft;
    double regionRight;
    if (p < 0.7) {
      final appear = p / 0.7;
      regionLeft = 0;
      regionRight = size.width * appear;
    } else {
      final disappear = (p - 0.7) / 0.3;
      regionLeft = size.width * disappear;
      regionRight = size.width;
    }

    if (regionRight <= regionLeft) {
      return;
    }

    final gridColor = const Color(0x336CE4FF);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    const cell = 16.0;
    for (double x = regionLeft; x <= regionRight; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(regionLeft, y), Offset(regionRight, y), gridPaint);
    }

    const bandWidth = 24.0;
    final bandLeft = (regionRight - bandWidth).clamp(regionLeft, regionRight);
    final bandRight = regionRight;
    if (bandRight <= bandLeft) {
      return;
    }
    final bandRect = Rect.fromLTRB(bandLeft, 0, bandRight, size.height);
    final bandPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0x006CE4FF), Color(0x446CE4FF)],
      ).createShader(bandRect);
    canvas.drawRect(bandRect, bandPaint);
  }

  @override
  bool shouldRepaint(covariant _HoloGridPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}