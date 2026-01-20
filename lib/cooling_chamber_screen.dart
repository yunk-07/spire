// cooling_chamber_screen.dart
// 作用：冷却间页面，提供深度冷却（中等修复 + 下战初始防火墙）
import 'package:flutter/material.dart';
import 'start_screen.dart';
import 'game_state.dart';
import 'main.dart';
import 'map_screen.dart';
import 'level_data.dart';

class CoolingChamberScreen extends StatelessWidget {
  final String levelId;
  const CoolingChamberScreen({super.key, required this.levelId});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF6CE4FF);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit(context);
        if (shouldExit && context.mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _metaRow(),
                  const SizedBox(height: 48),
                  Center(
                    child: _logicPanel(
                      CyberButton(
                        width: 320,
                        height: 44,
                        fontSize: 12,
                        label: '深度冷却：恢复 30 + 初始防火墙 +15',
                        color: const Color(0xFF6CE4FF),
                        onPressed: () {
                          GameState.heal(30);
                          GameState.playerBlock = 15;
                          GameProgress.markDefeated(levelId);
                          Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final res = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "DISCONNECT_CONFIRM",
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F16).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFF6A6A).withValues(alpha: 0.8), width: 2),
                boxShadow: [BoxShadow(color: const Color(0xFFFF6A6A).withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 2)],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: const CyberScanline(color: Color(0x11FF6A6A)),
                    ),
                  ),
                  Positioned.fill(child: CustomPaint(painter: CyberCornerPainter(color: const Color(0x66FF6A6A)))),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6A6A), size: 20),
                          SizedBox(width: 10),
                          Text(
                            "DISCONNECT_REQUEST",
                            style: TextStyle(color: Color(0xFFFF6A6A), fontSize: 10, fontFamily: 'monospace', letterSpacing: 2, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '即将终止当前的尖塔渗透任务，未同步的数据流将会丢失。是否确认断开物理接入？',
                        style: TextStyle(color: Color(0xFFE1E9FF), fontSize: 14, height: 1.6, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CyberButton(width: 100, height: 36, fontSize: 12, label: '维持接入', color: const Color(0xFF6CE4FF), onPressed: () => Navigator.pop(ctx, false)),
                          const SizedBox(width: 16),
                          CyberButton(width: 100, height: 36, fontSize: 12, label: '确认断开', color: const Color(0xFFFF6A6A), onPressed: () => Navigator.pop(ctx, true)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return res ?? false;
  }
}

Widget _logicPanel(Widget child) {
  final color = const Color(0xFF6CE4FF);
  return Container(
    width: 620,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    decoration: BoxDecoration(color: const Color(0xFF0A0F16).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 2), const BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))]),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Stack(
        children: [
          Positioned.fill(child: CyberScanline(color: color.withValues(alpha: 0.08))),
          Positioned.fill(child: CustomPaint(painter: CyberCornerPainter(color: color.withValues(alpha: 0.5)))),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [Icon(Icons.ac_unit, size: 16, color: color), const SizedBox(width: 8), Text("// COOLING_CHANNEL", style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'monospace', letterSpacing: 2)), const Spacer(), Text("SESSION", style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))]),
              const SizedBox(height: 12),
              Container(width: double.infinity, height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.2), Colors.transparent]))),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildHeader() {
  return Column(
    children: const [
      Text('冷却间', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8, fontFamily: 'monospace', shadows: [Shadow(color: Color(0xFF6CE4FF), blurRadius: 20)])),
      SizedBox(height: 12),
      Text('COOLING CHAMBER v3.4', style: TextStyle(fontSize: 10, color: Color(0x666CE4FF), letterSpacing: 2, fontFamily: 'monospace')),
    ],
  );
}

Widget _metaRow() {
  final color = const Color(0xFF6CE4FF);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10)]), child: Row(children: [Icon(Icons.ac_unit, size: 14, color: color), const SizedBox(width: 6), const Text("OPTIONS: 1", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))])),
        const SizedBox(width: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4))), child: Row(children: [Icon(Icons.memory, size: 14, color: color), const SizedBox(width: 6), const Text("NODE", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1))])),
      ],
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF6CE4FF).withValues(alpha: 0.05)..strokeWidth = 1;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
