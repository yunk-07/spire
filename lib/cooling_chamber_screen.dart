// cooling_chamber_screen.dart
// 作用：冷却间页面，提供深度冷却（中等修复 + 下战初始防火墙）
import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'game_state.dart';
import 'main.dart';
import 'map_screen.dart';
import 'level_data.dart';

class CoolingChamberScreen extends StatelessWidget {
  final LevelInfo? level;
  const CoolingChamberScreen({super.key, this.level});

  String get levelId => level?.id ?? 'UNKNOWN';
  String get levelTitle => level?.title ?? '冷却间';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showCyberConfirmExit(context);
        if (shouldExit && context.mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        body: Stack(
          children: [
            const Positioned.fill(
              child: CyberBackground(),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _buildHeader(),
                          const SizedBox(height: 12),
                          _metaRow(),
                          const SizedBox(height: 48),
                          Center(
                            child: CyberLogicPanel(
                              color: GameState.getThemeColor(),
                              icon: Icons.ac_unit,
                              label: "// COOLING_CHANNEL",
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CyberButton(
                                  width: 320,
                                  height: 60,
                                  fontSize: 14,
                                  label: '深度冷却：恢复 30 + 永久防火墙 +5',
                                  color: GameState.getThemeColor(),
                                  onPressed: () {
                                    GameState.heal(30);
                                    GameState.permanentBlock += 5;
                                    GameProgress.markDefeated(levelId);
                                    Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final color = GameState.getThemeColor();
    return Column(
      children: [
        Text(levelTitle, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8, fontFamily: 'monospace', shadows: [Shadow(color: color, blurRadius: 20)])),
        const SizedBox(height: 12),
        Text('COOLING CHAMBER v3.4', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.4), letterSpacing: 2, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _metaRow() {
    final color = GameState.getThemeColor();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10)]), child: Row(children: [Icon(Icons.ac_unit, size: 14, color: color), const SizedBox(width: 6), const Text("OPTIONS: 1", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))])),
          const SizedBox(width: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4))), child: Row(children: [Icon(Icons.memory, size: 14, color: color), const SizedBox(width: 6), Text("NODE: $levelId", style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1))])),
        ],
      ),
    );
  }
}


