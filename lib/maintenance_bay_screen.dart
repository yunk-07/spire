// maintenance_bay_screen.dart
// 作用：维保处页面，提供随机添加一张牌（可选择要或不要），接受则同时恢复10
import 'package:flutter/material.dart';
import 'dart:math';
import 'start_screen.dart';
import 'game_state.dart';
import 'card_data.dart';
import 'main.dart';
import 'map_screen.dart';
import 'level_data.dart';

class MaintenanceBayScreen extends StatelessWidget {
  final String levelId;
  const MaintenanceBayScreen({super.key, required this.levelId});

  @override
  Widget build(BuildContext context) {
    final themeColor = GameState.getThemeColor();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit(context, themeColor);
        if (shouldExit && context.mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter(themeColor))),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(themeColor),
                  const SizedBox(height: 12),
                  _metaRow(themeColor),
                  const SizedBox(height: 48),
                  Center(
                    child: _logicPanel(
                      CyberButton(
                        width: 360,
                        height: 44,
                        fontSize: 12,
                        label: '维保检修：随机提供一张牌（可选），接受则修复10',
                        color: themeColor,
                        onPressed: () async {
                          final random = Random();
                          // 关键区域：排除恶魔和神圣系列卡牌（仅限Boss奖励）
                          final availableCards = cardDatabase.values.where((c) => c.suite != CardSuite.demon && c.suite != CardSuite.holy).toList();
                          if (availableCards.isEmpty) {
                            CyberToast.show(context, '数据库暂无可用卡牌');
                            return;
                          }
                          final card = availableCards[random.nextInt(availableCards.length)];
                          final cardId = card.id;
                          final accepted = await _showOfferDialog(context, cardId, card.name, card.description ?? '', themeColor);
                          if (accepted == true) {
                            if (!GameState.drawPile.contains(cardId)) {
                              GameState.drawPile.add(cardId);
                            }
                            GameState.heal(10);
                          }
                          GameProgress.markDefeated(levelId);
                          Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
                        },
                      ),
                      themeColor,
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

  Future<bool> _confirmExit(BuildContext context, Color themeColor) async {
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
                border: Border.all(color: themeColor.withValues(alpha: 0.8), width: 2),
                boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 2)],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: CyberScanline(color: themeColor.withValues(alpha: 0.07)),
                    ),
                  ),
                  Positioned.fill(child: CustomPaint(painter: CyberCornerPainter(color: themeColor.withValues(alpha: 0.5)))),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: themeColor, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "DISCONNECT_REQUEST",
                            style: TextStyle(color: themeColor, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2, fontWeight: FontWeight.bold),
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
                          CyberButton(width: 100, height: 36, fontSize: 12, label: '维持接入', color: Colors.grey, onPressed: () => Navigator.pop(ctx, false)),
                          const SizedBox(width: 16),
                          CyberButton(width: 100, height: 36, fontSize: 12, label: '确认断开', color: themeColor, onPressed: () => Navigator.pop(ctx, true)),
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

  Future<bool?> _showOfferDialog(BuildContext context, String cardId, String name, String desc, Color themeColor) async {
    final accent = themeColor;
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "MAINTENANCE_OFFER",
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, a1, a2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F16).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 2)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build_circle, color: accent, size: 20),
                      const SizedBox(width: 10),
                      Text("维保检修提议", style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                  Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5, fontFamily: 'monospace')),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CyberButton(width: 120, height: 36, fontSize: 12, label: '拒绝', color: Colors.grey, onPressed: () => Navigator.pop(ctx, false)),
                      const SizedBox(width: 12),
                      CyberButton(width: 160, height: 36, fontSize: 12, label: '接受并修复10', color: accent, onPressed: () => Navigator.pop(ctx, true)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _logicPanel(Widget child, Color color) {
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
              Row(children: [Icon(Icons.build_circle, size: 16, color: color), const SizedBox(width: 8), Text("// MAINTENANCE_CHANNEL", style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'monospace', letterSpacing: 2)), const Spacer(), Text("SESSION", style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))]),
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

Widget _buildHeader(Color themeColor) {
  return Column(
    children: [
      Text('维保处', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8, fontFamily: 'monospace', shadows: [Shadow(color: themeColor, blurRadius: 20)])),
      const SizedBox(height: 12),
      Text('MAINTENANCE BAY v3.4', style: TextStyle(fontSize: 10, color: themeColor.withValues(alpha: 0.4), letterSpacing: 2, fontFamily: 'monospace')),
    ],
  );
}

Widget _metaRow(Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10)]), child: Row(children: [Icon(Icons.build, size: 14, color: color), const SizedBox(width: 6), const Text("OPTIONS: 1", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))])),
        const SizedBox(width: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10)]), child: Row(children: [Icon(Icons.shield, size: 14, color: color), const SizedBox(width: 6), Text("HP: ${GameState.playerHp}/${GameState.playerMaxHp}", style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))])),
      ],
    ),
  );
}

class _GridPainter extends CustomPainter {
  final Color themeColor;
  _GridPainter(this.themeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = themeColor.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
