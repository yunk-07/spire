// huozhan_page.dart
// 作用：货栈页面，横向展示5张随机卡牌，可选择其中一张加入牌堆
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'start_screen.dart';
import 'map_screen.dart';
import 'card_data.dart';
import 'game_state.dart';
import 'level_data.dart';
// import 'rest_page.dart';
import 'core/route.dart' show createHoloRoute;
import 'exchange_page.dart';

class HuozhanPage extends StatefulWidget {
  final String levelId;
  const HuozhanPage({super.key, required this.levelId});
  @override
  State<HuozhanPage> createState() => _HuozhanPageState();
}

class _HuozhanPageState extends State<HuozhanPage> {
  late final List<CardData> _cards;

  @override
  void initState() {
    super.initState();
    final random = Random();
    final ids = List<String>.from(GameState.drawPile);
    final fromDeck = ids.map((id) => cardDatabase[id]).whereType<CardData>().toList();
    final pool = List<CardData>.from(fromDeck);
    final picked = <CardData>[];
    while (picked.length < 5 && pool.isNotEmpty) {
      final idx = random.nextInt(pool.length);
      picked.add(pool.removeAt(idx));
    }
    _cards = picked;
  }

  @override
  void dispose() {
    super.dispose();
  }

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
            // 背景采用与逻辑交易所一致的网格绘制
            Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _DepotGridPainter()))),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(color),
                  const SizedBox(height: 12),
                  _metaRow(color),
                  const SizedBox(height: 48),
                  Expanded(
                    child: Center(
                      child: _logicPanel(
                        color,
                        _buildDepotContent(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Text(
                      '请选择一张货栈卡牌以继续...',
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Column(
      children: [
        const Text(
          '货栈',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 8,
            fontFamily: 'monospace',
            shadows: [Shadow(color: Color(0xFF6CE4FF), blurRadius: 20)],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'DEPOT PROTOCOL v3.4',
          style: TextStyle(
            fontSize: 10,
            color: Color(0x666CE4FF),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0F16),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.4)),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  "OPTIONS: ${_cards.length}",
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
                  "NODE: ${widget.levelId}",
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

  // 逻辑面板：沿用交易所页面的框体与装饰
  Widget _logicPanel(Color color, Widget child) {
    return RepaintBoundary(
      child: Container(
      width: 720,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 2),
          const BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            Positioned.fill(child: CyberScanline(color: color.withValues(alpha: 0.08))),
            Positioned.fill(child: CustomPaint(painter: CyberCornerPainter(color: color.withValues(alpha: 0.5)))),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2, size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(
                      "// DEPOT_CHANNEL",
                      style: TextStyle(
                        color: color.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "SESSION",
                      style: TextStyle(
                        color: color.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.2), Colors.transparent]),
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  // 货栈内容：在逻辑面板中展示横向卡牌列表
  Widget _buildDepotContent() {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _cards.length,
        itemBuilder: (_, i) => _cardTile(_cards[i]),
      ),
    );
  }


  Widget _cardTile(CardData c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: 160,
        height: 240,
        child: Stack(
          children: [
            Positioned.fill(child: gameCardWidget(c, onTap: () => _select(c))),
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.storage, size: 12, color: Color(0xFFFFD700)),
                    SizedBox(width: 4),
                    Text('高价值缓存', style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(CardData c) async {
    if (!GameState.drawPile.contains(c.id)) {
      GameState.drawPile.add(c.id);
    }
    GameProgress.markDefeated(widget.levelId);
    if (mounted) {
      CyberToast.show(context, '已从货栈获取卡牌 [${c.name}]');
      Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
    }
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

  // 无本地卡牌渲染辅助
}

// 货栈背景网格Painter：与交易所页面风格一致
class _DepotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6CE4FF).withValues(alpha: 0.05)
      ..strokeWidth = 1;
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
