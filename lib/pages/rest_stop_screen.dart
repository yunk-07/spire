// rest_stop_screen.dart
// 作用：歇脚点页面，小幅恢复并提升下一战的初始算力
import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../models/game_state.dart';
import '../main.dart';
import 'map_screen.dart';
import '../models/level_data.dart';

class RestStopScreen extends StatelessWidget {
  final LevelInfo? level;
  const RestStopScreen({super.key, this.level});

  String get levelId => level?.id ?? 'UNKNOWN';
  String get levelTitle => level?.title ?? '未知区域';

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
                              icon: Icons.tips_and_updates,
                              label: "// 歇脚点",
                              child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: ThemeConfig.buildCyberDecoration(GameState.getThemeColor()),
                                child: CyberButton(
                                  width: 280,
                                  height: 60,
                                  fontSize: 14,
                                  label: '短暂歇脚：恢复 20 + 永久算力 +1',
                                  color: GameState.getThemeColor(),
                                  onPressed: () {
                                    GameState.heal(20);
                                    GameState.permanentStrength += 1;
                                    GameProgress.markDefeated(levelId);
                                    Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
                                  },
                                ),
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
        Text('补给站点 v3.4', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.4), letterSpacing: 2, fontFamily: 'monospace')),
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
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: ThemeConfig.buildCyberDecoration(color), child: Row(children: [Icon(Icons.tips_and_updates, size: 14, color: color), const SizedBox(width: 6), const Text("可用操作: 1", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))])),
          const SizedBox(width: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: ThemeConfig.buildCyberDecoration(color, isRight: true), child: Row(children: [Icon(Icons.memory, size: 14, color: color), const SizedBox(width: 6), Text("节点编号: $levelId", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1))])),
        ],
      ),
    );
  }
}
