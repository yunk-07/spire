import 'package:flutter/material.dart';
import '../game_state.dart';

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
                    painter: _HoloGridPainter(progress: t),
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

class _HoloGridPainter extends CustomPainter {
  final double progress;

  _HoloGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.05) {
      return;
    }
    final p = progress.clamp(0.0, 1.0);

    double regionTop;
    double regionBottom;
    if (p < 0.7) {
      final appear = p / 0.7;
      regionTop = 0;
      regionBottom = size.height * appear;
    } else {
      final disappear = (p - 0.7) / 0.3;
      regionTop = size.height * disappear;
      regionBottom = size.height;
    }

    if (regionBottom <= regionTop) {
      return;
    }

    final themeColor = GameState.getThemeColor();
    final gridColor = themeColor.withValues(alpha: 0.2);
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1;

    const cell = 16.0;
    for (double y = regionTop; y <= regionBottom; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, regionTop), Offset(x, regionBottom), gridPaint);
    }

    const bandHeight = 24.0;
    final bandTop = (regionBottom - bandHeight).clamp(regionTop, regionBottom);
    final bandBottom = regionBottom;
    if (bandBottom <= bandTop) {
      return;
    }
    final bandRect = Rect.fromLTRB(0, bandTop, size.width, bandBottom);
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [themeColor.withValues(alpha: 0.0), themeColor.withValues(alpha: 0.26)],
      ).createShader(bandRect);
    canvas.drawRect(bandRect, bandPaint);
  }

  @override
  bool shouldRepaint(covariant _HoloGridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
