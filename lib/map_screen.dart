// map_screen.dart
// 作用：提供树状地图选择界面，用于查看已击败与下一层可挑战的关卡

import 'package:flutter/material.dart';
import 'start_screen.dart';
import 'level_data.dart';
import 'game_state.dart';
import 'main.dart';

// 连接线使用层间全连接的方式在画笔中生成

/// 树状地图页面
class MapScreen extends StatelessWidget {
  final bool canReturnToGame;
  const MapScreen({super.key, this.canReturnToGame = false});

  // 关键区域：地图结构定义（三层）
  List<List<LevelInfo>> get _layers => levelLayers;

  // 连接关系由画笔按层自动生成

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (canReturnToGame) {
          Navigator.pop(context);
          return false;
        }
        return _confirmExit(context);
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('轨道节点图', style: TextStyle(color: Color(0xFFE1E9FF), fontWeight: FontWeight.w500, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF8FA3C0)),
          onPressed: () {
            if (canReturnToGame) {
              Navigator.pop(context);
            } else {
              _confirmExit(context);
            }
          },
        ),
      ),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(400),
        minScale: 0.6,
        maxScale: 2.0,
        child: SizedBox(
          width: 1200,
          height: 1600,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF05060A), Color(0xFF0C1018)],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapPainter(layers: _layers),
                ),
              ),
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < _layers.length; i++)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _layers[i]
                            .map((node) => _nodeWidget(context, node, i))
                            .toList(),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  bottom: true,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Visibility(
                      visible: canReturnToGame,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          backgroundColor: const Color(0xFF101722),
                          foregroundColor: const Color(0xFF6CE4FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: const BorderSide(color: Color(0xFF2A4158)),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('返回战斗', style: TextStyle(letterSpacing: 2)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // 关键区域：节点状态展示（已击败/下一层可挑战/未解锁）
  Widget _nodeWidget(BuildContext context, LevelInfo node, int layerIndex) {
    final defeated = GameProgress.isDefeated(node.id);
    final isNext = layerIndex == GameProgress.currentLayer + 1;
    final nodeIndex = levelLayers[layerIndex].indexOf(node);
    final allowedIndices = GameProgress.allowedNextIndices();
    final isAllowed = isNext && allowedIndices.contains(nodeIndex);
    final isCurrent = layerIndex == GameProgress.currentLayer && node.id == GameProgress.currentLevelId;
    Color base;
    switch (node.type) {
      case 'rest':
        base = const Color(0xFF1B2B38);
        break;
      case 'shop':
        base = const Color(0xFF222742);
        break;
      default:
        base = const Color(0xFF162632);
    }
    final color = defeated
        ? const Color(0xFF1E3B3F)
        : (isAllowed ? base.withValues(alpha: 0.95) : base.withValues(alpha: 0.55));
    IconData icon;
    switch (node.type) {
      case 'rest':
        icon = Icons.self_improvement;
        break;
      case 'shop':
        icon = Icons.storefront;
        break;
      default:
        icon = Icons.place;
    }

    return GestureDetector(
      onTap: () {
        if (!isAllowed && !isCurrent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('只能前往相邻的区域')),
          );
          return;
        }
        if (node.type == 'battle') {
          GameProgress.setCurrentLevel(node);
          Navigator.push(
            context,
            createHoloRoute(
              BattlePage(
                monsterIds: node.monsterIds,
                levelId: node.id,
              ),
            ),
          );
        } else if (node.type == 'rest') {
          final heal = (GameState.playerMaxHp * 0.3).round();
          GameState.heal(heal);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('在休息区恢复了$heal点生命')),
          );
          GameProgress.markDefeated(node.id);
        } else if (node.type == 'shop') {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('商店'),
              content: const Text('购买治疗药水 +20 HP'),
              actions: [
                TextButton(
                  onPressed: () {
                    GameState.heal(20);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('购买并恢复了20点生命')),
                    );
                    GameProgress.markDefeated(node.id);
                  },
                  child: const Text('购买'),
                ),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('离开')),
              ],
            ),
          );
        }
      },
      child: SizedBox(
        width: 140,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isCurrent
                      ? const Color(0xFF6CE4FF)
                      : (isAllowed ? const Color(0xFF2A4158) : const Color(0xFF111720)),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black, blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: isCurrent ? const Color(0xFF6CE4FF) : const Color(0xFF8FA3C0), size: 18),
                  const SizedBox(height: 6),
                  Text(
                    node.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFE1E9FF), fontWeight: FontWeight.w500, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Positioned(
                top: -14,
                left: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101722),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFF6CE4FF)),
                  ),
                  child: const Text(
                    "ACTIVE",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Color(0xFF6CE4FF)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmExit(BuildContext context) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('确认返回？'),
      content: const Text('将返回到开始页面并结束当前游戏'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              createHoloRoute(const StartScreen()),
              (route) => false,
            );
          },
          child: const Text('确定'),
        ),
      ],
    ),
  );
  return Future.value(res ?? false);
}

/// 关键区域：自定义画笔，绘制层间连接线
class _MapPainter extends CustomPainter {
  final List<List<LevelInfo>> layers;
  _MapPainter({required this.layers});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 计算每层与每个节点的位置
    final layerCount = layers.length;
    final layerHeight = size.height / (layerCount + 1);

    final positions = <String, Offset>{};
    for (int i = 0; i < layerCount; i++) {
      final layer = layers[i];
      final y = (i + 1) * layerHeight;
      final spacing = size.width / (layer.length + 1);
      for (int j = 0; j < layer.length; j++) {
        final x = (j + 1) * spacing;
        positions[layer[j].id] = Offset(x, y);
      }
    }

    // 绘制层间全连接边（每层到下一层）
    for (int i = 0; i < layerCount - 1; i++) {
      final current = layers[i];
      final next = layers[i + 1];
      for (final a in current) {
        for (final b in next) {
          final p1 = positions[a.id]!;
          final p2 = positions[b.id]!;
          final path = Path()
            ..moveTo(p1.dx, p1.dy)
            ..quadraticBezierTo(
              (p1.dx + p2.dx) / 2,
              (p1.dy + p2.dy) / 2 - 40,
              p2.dx,
              p2.dy,
            );
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
