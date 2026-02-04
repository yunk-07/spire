// shujugui_page.dart
// 作用：数据柜页面，沿用“货栈”UI样式，横向展示5张随机卡牌，可选择加入
import 'package:flutter/material.dart';
import 'dart:math';
import 'map_screen.dart';
import 'card_data.dart';
import 'game_state.dart';
import 'level_data.dart';
// import 'rest_page.dart';
import 'core/route.dart' show createHoloRoute;
import 'theme_config.dart';

class ShujuguiPage extends StatefulWidget {
  final LevelInfo? level;
  const ShujuguiPage({super.key, this.level});
  @override
  State<ShujuguiPage> createState() => _ShujuguiPageState();
}

class _ShujuguiPageState extends State<ShujuguiPage> {
  late final List<CardData> _cards;
  late final List<int> _prices;

  LevelInfo? get node => widget.level;
  String get levelId => node?.id ?? 'UNKNOWN';
  String get levelTitle => node?.title ?? '数据柜';

  @override
  void initState() {
    super.initState();
    final random = Random();
    // 关键区域：排除恶魔和神圣系列卡牌（仅限Boss奖励）
    final high = cardDatabase.values.where((c) => c.level >= 4 && c.suite != CardSuite.demon && c.suite != CardSuite.holy).toList();
    final pool = List<CardData>.from(high);
    final picked = <CardData>[];
    final prices = <int>[];
    while (picked.length < 2 && pool.isNotEmpty) {
      final card = pool.removeAt(random.nextInt(pool.length));
      picked.add(card);
      // 价格逻辑：基础价格(等级*20 + 30) + 随机浮动(-10到20)
      int basePrice = card.level * 20 + 30;
      int offset = random.nextInt(31) - 10;
      prices.add(basePrice + offset);
    }
    _cards = picked;
    _prices = prices;
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
                              label: "// 数据柜",
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: ThemeConfig.buildCyberDecoration(color),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: Row(children: List.generate(_cards.length, (i) => _cardTile(_cards[i], _prices[i]))),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildGoldDisplay(color),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Text(
                              '请消耗信用点选择一张数据柜卡牌以继续...',
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

  Widget _buildGoldDisplay(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: ThemeConfig.buildCyberDecoration(const Color(0xFFFFD700)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
          const SizedBox(width: 8),
          Text(
            '当前信用点: ${GameState.playerGold}',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Column(
      children: [
        Text(levelTitle, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8, fontFamily: 'monospace', shadows: [Shadow(color: color, blurRadius: 20)])),
        const SizedBox(height: 12),
        Text('数据柜协议 v3.4', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.4), letterSpacing: 2, fontFamily: 'monospace')),
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
            child: Row(children: [Icon(Icons.storage, size: 14, color: color), const SizedBox(width: 6), Text("可供选择: ${_cards.length}", style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2, fontWeight: FontWeight.bold))]),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: ThemeConfig.buildCyberDecoration(color, isRight: true),
            child: Row(children: [Icon(Icons.memory, size: 14, color: color), const SizedBox(width: 6), Text("节点: $levelId", style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1))]),
          ),
        ],
      ),
    );
  }


  Widget _cardTile(CardData c, int price) {
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
                onTap: () => _select(c, price),
                child: ThemeConfig.buildCardWidget(c, width: 160, height: 240),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: ThemeConfig.buildCyberDecoration(const Color(0xFFE26CFF)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storage, size: 11, color: Color(0xFFE26CFF)),
                    const SizedBox(width: 4),
                    Text(
                      '封存 $price',
                      style: const TextStyle(
                        color: Color(0xFFE26CFF),
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
