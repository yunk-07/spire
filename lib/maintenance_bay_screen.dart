// maintenance_bay_screen.dart
// 作用：维保处页面，提供随机添加一张牌（可选择要或不要），接受则同时恢复10
import 'package:flutter/material.dart';
import 'dart:math';
import 'theme_config.dart';
import 'game_state.dart';
import 'card_data.dart';
import 'main.dart';
import 'map_screen.dart';
import 'level_data.dart';

class MaintenanceBayScreen extends StatelessWidget {
  final LevelInfo? level;
  const MaintenanceBayScreen({super.key, this.level});

  String get levelId => level?.id ?? 'UNKNOWN';
  String get levelTitle => level?.title ?? '维保处';

  @override
  Widget build(BuildContext context) {
    final themeColor = GameState.getThemeColor();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showCyberConfirmExit(context, color: themeColor);
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
                          _buildHeader(themeColor),
                          const SizedBox(height: 12),
                          _metaRow(themeColor),
                          const SizedBox(height: 48),
                          Center(
                            child: CyberLogicPanel(
                              color: themeColor,
                              icon: Icons.build,
                              label: "// 维保处",
                              child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: ThemeConfig.buildCyberDecoration(themeColor),
                                child: Column(
                                  children: [
                                    CyberButton(
                                      width: 360,
                                      height: 60,
                                      fontSize: 14,
                                      label: '维保检修：随机一张牌，接受则修复10',
                                      color: themeColor,
                                      onPressed: () async {
                                        final random = Random();
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
                                        if (context.mounted) {
                                          Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    CyberButton(
                                      width: 360,
                                      height: 60,
                                      fontSize: 14,
                                      label: '系统强化：永久增加 1 点算力',
                                      color: const Color(0xFF6CFF9E),
                                      onPressed: () {
                                        GameState.permanentStrength += 1;
                                        GameProgress.markDefeated(levelId);
                                        if (context.mounted) {
                                          CyberToast.show(context, '维保完成：永久算力 +1');
                                          Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
                                        }
                                      },
                                    ),
                                  ],
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

  Widget _buildHeader(Color themeColor) {
    return Column(
      children: [
        Text(levelTitle, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8, fontFamily: 'monospace', shadows: [Shadow(color: themeColor, blurRadius: 20)])),
        const SizedBox(height: 12),
        Text('维保终端 v3.4', style: TextStyle(fontSize: 10, color: themeColor.withValues(alpha: 0.4), letterSpacing: 2, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _metaRow(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: ThemeConfig.buildCyberDecoration(color), child: Row(children: [Icon(Icons.memory, size: 14, color: color), const SizedBox(width: 6), Text("节点编号: $levelId", style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1))])),
          const SizedBox(width: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: ThemeConfig.buildCyberDecoration(color, isRight: true), child: Row(children: [Icon(Icons.shield, size: 14, color: color), const SizedBox(width: 6), Text("${GameState.playerHp} / ${GameState.playerMaxHp}", style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))])),
        ],
      ),
    );
  }
}

// 移除底部的冗余函数定义


