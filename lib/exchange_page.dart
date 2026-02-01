// exchange_page.dart
// 作用：提供数据交易所界面，玩家可以在此选择并获得新的卡牌

import 'package:flutter/material.dart';
import 'game_state.dart';
import 'card_data.dart';
import 'level_data.dart';
import 'core/route.dart' show createHoloRoute;
import 'map_screen.dart';
import 'theme_config.dart';

class ExchangePage extends StatefulWidget {
  final LevelInfo? level;
  const ExchangePage({super.key, this.level});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  bool _hasChosen = false;

  LevelInfo? get node => widget.level;
  String get levelId => node?.id ?? 'UNKNOWN';
  String get levelTitle => node?.title ?? '交易所';

  @override
  void initState() {
    super.initState();
  }

  void _healHalfLost() {
    if (_hasChosen) return;
    final maxHp = GameState.playerMaxHp;
    final hp = GameState.playerHp;
    final lost = (maxHp - hp).clamp(0, maxHp);
    final heal = (lost * 0.5).floor();
    GameState.playerHp = (hp + heal).clamp(0, maxHp);
    setState(() {
      _hasChosen = true;
    });
    if (mounted) {
      Navigator.pushReplacement(
        context,
        createHoloRoute(const MapScreen(canSelect: true)),
      );
    }
  }

  void _chooseCardToRemove() async {
    if (_hasChosen) return;
    final ids = List<String>.from(GameState.drawPile);
    if (ids.isEmpty) {
      CyberToast.show(context, "当前牌堆为空，无法移除");
      return;
    }
    final removed = await _showRemoveDialog(context, ids);
    if (removed != null) {
      GameState.drawPile.remove(removed);
      setState(() {
        _hasChosen = true;
      });
      if (mounted) {
        Navigator.pushReplacement(
          context,
          createHoloRoute(const MapScreen(canSelect: true)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = GameState.getThemeColor();
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
            // 背景装饰
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
                          const SizedBox(height: 8),
                          _hpRow(themeColor),
                          const SizedBox(height: 48),
                          CyberLogicPanel(
                            color: themeColor,
                            label: "// LOGIC EXCHANGE",
                            child: _buildLogicExchangeOptions(themeColor),
                          ),
                          const SizedBox(height: 48),
                          Padding(
                              padding: const EdgeInsets.only(bottom: 40),
                              child: Text(
                                '请选择一个逻辑交易项以继续...',
                                style: TextStyle(
                                  color: themeColor.withValues(alpha: 0.6),
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
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

  Widget _metaRow(Color themeColor) {
    final color = themeColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0F16),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.tune, size: 12, color: color),
                const SizedBox(width: 6),
                Text(
                  "OPTIONS: 2",
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0F16),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.memory, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  "NODE: $levelId",
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hpRow(Color themeColor) {
    final color = themeColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F16),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 6),
            Text(
              "ITG: ${GameState.playerHp}/${GameState.playerMaxHp}",
              style: TextStyle(color: color, fontSize: 12, fontFamily: 'monospace', letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color themeColor) {
    return Column(
      children: [
        Text(
          levelTitle,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 8,
            fontFamily: 'monospace',
            shadows: [
              Shadow(color: themeColor, blurRadius: 20),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'LOGIC EXCHANGE PROTOCOL v3.4',
          style: TextStyle(
            fontSize: 10,
            color: themeColor.withValues(alpha: 0.4),
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildLogicExchangeOptions(Color themeColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _optionTile(
            label: "恢复已损失生命的 50%",
            icon: Icons.healing,
            color: themeColor,
            onTap: _healHalfLost,
            description: "根据缺失生命计算恢复量，立即生效。",
          ),
          const SizedBox(height: 20),
          _optionTile(
            label: "移除一张牌",
            icon: Icons.delete_forever,
            color: const Color(0xFFFF6A6A),
            onTap: _chooseCardToRemove,
            description: "从当前牌堆中永久移除一张牌。",
          ),
        ],
      ),
    );
  }


  Widget _optionTile({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String description,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 440,
        height: 130,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 16, spreadRadius: 2),
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(3, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CyberScanline(color: color.withValues(alpha: 0.12)),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: CyberCornerPainter(color: color.withValues(alpha: 0.25))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0F16),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withValues(alpha: 0.6)),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8)],
                      ),
                      child: Icon(icon, size: 22, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "LOGIC",
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.8),
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.2)]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontFamily: 'monospace',
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showRemoveDialog(BuildContext context, List<String> ids) async {
    final themeColor = GameState.getThemeColor();
    return await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "REMOVE_CARD",
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F16).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: themeColor.withValues(alpha: 0.7)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "选择要移除的牌",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          for (final id in ids) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Builder(
                                builder: (_) {
                                  final data = cardDatabase[id];
                                  if (data == null) {
                                    return Container(
                                      width: 160,
                                      height: 240,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF101722),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: themeColor.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(id, style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace')),
                                    );
                                  }
                                  return GestureDetector(
                                    onTap: () => Navigator.pop(ctx, id),
                                    child: ThemeConfig.buildCardWidget(data, width: 160, height: 240),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CyberButton(label: '取消', onPressed: () => Navigator.pop(ctx, null), width: 120, height: 40, fontSize: 12, color: themeColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
