// huozhan_page.dart
// 作用：货栈页面，横向展示5张随机卡牌，可选择其中一张加入牌堆
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'map_screen.dart';
import 'card_data.dart';
import 'game_state.dart';
import 'level_data.dart';
// import 'rest_page.dart';
import 'core/route.dart' show createHoloRoute;
import 'theme_config.dart';

class HuozhanPage extends StatefulWidget {
  final LevelInfo? level;
  const HuozhanPage({super.key, this.level});
  @override
  State<HuozhanPage> createState() => _HuozhanPageState();
}

class _HuozhanPageState extends State<HuozhanPage> {
  late final List<CardData> _cards;
  late final List<int> _prices;

  LevelInfo? get node => widget.level;
  String get levelId => node?.id ?? 'UNKNOWN';
  String get levelTitle => node?.title ?? '货栈';

  @override
  void initState() {
    super.initState();
    final random = Random();
    final ids = List<String>.from(GameState.drawPile);
    // 关键区域：从当前牌堆选取时也应排除恶魔和神圣卡牌（保持一致性）
    final fromDeck = ids.map((id) => cardDatabase[id])
        .whereType<CardData>()
        .where((c) => c.suite != CardSuite.demon && c.suite != CardSuite.holy)
        .toList();
    final pool = List<CardData>.from(fromDeck);
    final picked = <CardData>[];
    while (picked.length < 5 && pool.isNotEmpty) {
      final idx = random.nextInt(pool.length);
      picked.add(pool.removeAt(idx));
    }
    _cards = picked;
    
    // 关键区域：生成随机价格
    _prices = _cards.map((c) {
      int basePrice = 50;
      if (c.level == 2) basePrice = 80;
      if (c.level == 3) basePrice = 120;
      if (c.level == 4) basePrice = 180;
      if (c.level >= 5) basePrice = 250;
      
      // 价格浮动 80% - 120%
      return (basePrice * (0.8 + random.nextDouble() * 0.4)).floor();
    }).toList();
  }

  @override
  void dispose() {
    super.dispose();
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
                              icon: Icons.inventory_2,
                              label: "// 货栈频道",
                              child: _buildDepotContent(),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Text(
                              '请选择一张货栈卡牌以继续...',
                              style: TextStyle(
                                color: color.withValues(alpha: 0.6),
                                fontFamily: 'monospace',
                                fontSize: 12,
                                letterSpacing: 1.5,
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
        Text(
          levelTitle,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 8,
            fontFamily: 'monospace',
            shadows: [Shadow(color: color, blurRadius: 20)],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '货栈协议 v3.4',
          style: TextStyle(
            fontSize: 10,
            color: color.withValues(alpha: 0.4),
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _metaRow(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: ThemeConfig.buildCyberDecoration(color),
            child: Row(
              children: [
                Icon(Icons.inventory_2, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  "可供选择: ${_cards.length}",
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: ThemeConfig.buildCyberDecoration(color, isRight: true),
            child: Row(
              children: [
                Icon(Icons.memory, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  "节点: $levelId",
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
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: ThemeConfig.buildCyberDecoration(const Color(0xFFFFD700)),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, size: 14, color: Color(0xFFFFD700)),
                const SizedBox(width: 6),
                Text(
                  "${GameState.playerGold}",
                  style: const TextStyle(                    color: Color(0xFFFFD700),
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // 货栈内容：在逻辑面板中展示横向卡牌列表
  Widget _buildDepotContent() {
    final color = GameState.getThemeColor();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ThemeConfig.buildCyberDecoration(color),
      child: SizedBox(
        height: 290, // 增加高度以容纳价格
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: _cards.length,
          itemBuilder: (_, i) => _cardTile(_cards[i]),
        ),
      ),
    );
  }


  Widget _cardTile(CardData c) {
    final index = _cards.indexOf(c);
    final price = _prices[index];
    final canAfford = GameState.playerGold >= price;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        width: 160,
        height: 285, // 增加高度以容纳价格标签
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 15,
              left: 0,
              right: 0,
              bottom: 30, // 为底部价格腾出空间
              child: GestureDetector(
                onTap: () => _select(c, price),
                child: Opacity(
                  opacity: canAfford ? 1.0 : 0.6,
                  child: ThemeConfig.buildCardWidget(c, width: 160, height: 240),
                ),
              ),
            ),
            // 顶部提示标签
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: ThemeConfig.buildCyberDecoration(const Color(0xFFFFD700)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.inventory_2, size: 11, color: Color(0xFFFFD700)),
                    SizedBox(width: 4),
                    Text(
                      '高价值缓存',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
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
            // 底部价格标签
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: ThemeConfig.buildCyberDecoration(
                  canAfford ? const Color(0xFFFFD700) : Colors.red,
                  isRight: true,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 12,
                      color: canAfford ? const Color(0xFFFFD700) : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$price',
                      style: TextStyle(
                        color: canAfford ? const Color(0xFFFFD700) : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
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
    if (GameState.playerGold < price) {
      // 关键区域：检查是否买不起任何商品
      bool canAffordAny = _prices.any((p) => GameState.playerGold >= p);
      if (!canAffordAny) {
        if (mounted) {
          CyberToast.show(context, '你什么也买不起，被赏了20');
          GameState.playerGold += 20;
          GameProgress.markDefeated(levelId);
          Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
        }
        return;
      }
      CyberToast.show(context, '信用点不足，无法获取此卡牌');
      return;
    }

    GameState.playerGold -= price;
    if (!GameState.drawPile.contains(c.id)) {
      GameState.drawPile.add(c.id);
    }
    GameProgress.markDefeated(levelId);
    if (mounted) {
      CyberToast.show(context, '已消耗 $price 信用点获取卡牌 [${c.name}]');
      Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
    }
  }

  // 无本地卡牌渲染辅助
}
