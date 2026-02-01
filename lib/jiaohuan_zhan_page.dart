// jiaohuan_zhan_page.dart
// 作用：交换站页面，沿用“货栈”UI样式，横向展示5张随机卡牌，可选择加入
import 'package:flutter/material.dart';
import 'dart:math';
import 'map_screen.dart';
import 'card_data.dart';
import 'game_state.dart';
import 'level_data.dart';
// import 'rest_page.dart';
import 'core/route.dart' show createHoloRoute;
import 'theme_config.dart';

class JiaohuanZhanPage extends StatefulWidget {
  final LevelInfo? level;
  const JiaohuanZhanPage({super.key, this.level});
  @override
  State<JiaohuanZhanPage> createState() => _JiaohuanZhanPageState();
}

class _JiaohuanZhanPageState extends State<JiaohuanZhanPage> {
  late final List<CardData> _cards;
  late final List<int> _prices;

  LevelInfo? get node => widget.level;
  String get levelId => node?.id ?? 'UNKNOWN';
  String get levelTitle => node?.title ?? '交换站';

  @override
  void initState() {
    super.initState();
    final random = Random();
    // 关键区域：排除恶魔和神圣系列卡牌（仅限Boss奖励）
    final pool = cardDatabase.values.where((c) => c.suite != CardSuite.demon && c.suite != CardSuite.holy).toList();
    final picked = <CardData>[];
    while (picked.length < 5 && pool.isNotEmpty) {
      final idx = random.nextInt(pool.length);
      picked.add(pool.removeAt(idx));
    }
    _cards = picked;
    _prices = _cards.map((c) => 2 + c.level * 3 + random.nextInt(3)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final color = GameState.getThemeColor();
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
                          _buildHeader(color),
                          const SizedBox(height: 12),
                          _metaRow(color),
                          const SizedBox(height: 48),
                          Center(
                            child: CyberLogicPanel(
                              color: color,
                              label: "// EXCHANGE",
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Row(
                                  children: List.generate(_cards.length, (i) => _cardTile(_cards[i], i)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Text(
                              '请选择一张交换站卡牌以继续...',
                              style: TextStyle(
                                color: color.withValues(alpha: 0.6),
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

  Widget _buildHeader(Color color) {
    return Column(
      children: [
        Text(levelTitle, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8, fontFamily: 'monospace', shadows: [Shadow(color: color, blurRadius: 20)])),
        const SizedBox(height: 12),
        Text('SWITCH STATION v3.4', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.4), letterSpacing: 2, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _metaRow(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10)]),
            child: Row(children: [Icon(Icons.sync_alt, size: 14, color: color), const SizedBox(width: 6), Text("OPTIONS: ${_cards.length}", style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2, fontWeight: FontWeight.bold))]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4))),
            child: Row(children: [Icon(Icons.memory, size: 14, color: color), const SizedBox(width: 6), Text("NODE: $levelId", style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1))]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4))),
            child: Row(children: [Icon(Icons.favorite, size: 14, color: const Color(0xFFFF6A6A)), const SizedBox(width: 6), Text("HP: ${GameState.playerHp}/${GameState.playerMaxHp}", style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1))]),
          ),
        ],
      ),
    );
  }


  Widget _cardTile(CardData c, int i) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        width: 160,
        height: 255,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 15,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => _select(c, _prices[i]),
                child: ThemeConfig.buildCardWidget(c, width: 160, height: 240),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomRight: Radius.circular(10),
                  ),
                  border: Border.all(color: const Color(0xFFFF6A6A).withValues(alpha: 0.8), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6A6A).withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, size: 11, color: Color(0xFFFF6A6A)),
                    const SizedBox(width: 4),
                    Text(
                      'HP -${_prices[i]}',
                      style: const TextStyle(
                        color: Color(0xFFFF6A6A),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(CardData c, int price) async {
    final hp = GameState.playerHp;
    if (hp < price) {
      CyberToast.show(context, '生命不足，无法交换');
      return;
    }
    GameState.playerHp = (hp - price).clamp(0, GameState.playerMaxHp);
    if (!GameState.drawPile.contains(c.id)) {
      GameState.drawPile.add(c.id);
    }
    GameProgress.markDefeated(levelId);
    if (mounted) {
      CyberToast.show(context, '消耗 $price 生命，获得 [${c.name}]');
      Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
    }
  }

  // 无本地卡牌渲染辅助
}
