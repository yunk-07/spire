import 'package:flutter/material.dart';
import '../theme_config.dart';

Route<T> createHoloRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 1200),
    reverseTransitionDuration: const Duration(milliseconds: 800),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return _HoloGridOverlay(animation: curved, child: child);
    },
  );
}

class _HoloGridOverlay extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _HoloGridOverlay({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final v = t.clamp(0.0, 1.0);
        return Stack(
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: v == 0 ? 0.001 : v,
                child: child,
              ),
            ),
            if (t > 0 && t < 1)
              IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: CyberHoloGridPainter(progress: t),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

