// exchange_page.dart
// 作用：提供数据交易所界面，玩家可以在此选择并获得新的卡牌

import 'dart:math';
import 'package:flutter/material.dart';
import 'game_state.dart';
import 'card_data.dart';
import 'main.dart';
import 'start_screen.dart';
import 'map_screen.dart';

class ExchangePage extends StatefulWidget {
  final String? levelId;
  const ExchangePage({super.key, this.levelId});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  List<CardData> _offeredCards = [];
  bool _hasChosen = false;

  @override
  void initState() {
    super.initState();
    _generateOffers();
  }

  void _generateOffers() {
    final allCardIds = cardDatabase.keys.toList();
    final random = Random();
    final List<CardData> selected = [];
    
    // 随机选择3张不同的卡牌
    while (selected.length < 3 && allCardIds.isNotEmpty) {
      final id = allCardIds[random.nextInt(allCardIds.length)];
      final card = cardDatabase[id]!;
      if (!selected.any((c) => c.id == card.id)) {
        selected.add(card);
      }
    }
    setState(() {
      _offeredCards = selected;
    });
  }

  void _chooseCard(CardData card) {
    if (_hasChosen) return;
    
    setState(() {
      GameState.drawPile.add(card.id);
      _hasChosen = true;
    });

    // 立即跳转到地图页面
    if (mounted) {
      Navigator.pushReplacement(
        context,
        createHoloRoute(const MapScreen(canSelect: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // 背景装饰
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 60),
                  Expanded(
                    child: Center(
                      child: _buildCardOffers(),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Text(
                        '请选择一个指令集进行接入...',
                        style: TextStyle(
                          color: const Color(0xFF6CE4FF).withValues(alpha: 0.6),
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
                border: Border.all(
                  color: const Color(0xFFFF6A6A).withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6A6A).withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: const CyberScanline(color: Color(0x11FF6A6A)),
                    ),
                  ),
                  // 装饰边角
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CyberCornerPainter(color: const Color(0x66FF6A6A)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFF6A6A),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "DISCONNECT_REQUEST",
                            style: TextStyle(
                              color: Color(0xFFFF6A6A),
                              fontSize: 10,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '即将终止当前的尖塔渗透任务，未同步的数据流将会丢失。是否确认断开物理接入？',
                        style: TextStyle(
                          color: Color(0xFFE1E9FF),
                          fontSize: 14,
                          height: 1.6,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CyberButton(
                            width: 100,
                            height: 36,
                            fontSize: 12,
                            label: '维持接入',
                            color: const Color(0xFF6CE4FF),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                          const SizedBox(width: 16),
                          CyberButton(
                            width: 100,
                            height: 36,
                            fontSize: 12,
                            label: '确认断开',
                            color: const Color(0xFFFF6A6A),
                            onPressed: () => Navigator.pop(ctx, true),
                          ),
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
    return Future.value(res ?? false);
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          '数据交易所',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 8,
            fontFamily: 'monospace',
            shadows: [
              Shadow(color: Color(0xFF6CE4FF), blurRadius: 20),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'DATA EXCHANGE PROTOCOL v3.4',
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

  Widget _buildCardOffers() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _offeredCards.map((card) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GestureDetector(
            onTap: () => _chooseCard(card),
            child: _cardWidget(card),
          ),
        )).toList(),
      ),
    );
  }

  Widget _cardWidget(CardData c) {
    final suiteColor = _getSuiteColor(c.suite);
    final rarityColor = _getRarityColor(c.level);
    final cardBgColor = _getCardBgColor(c.suite).withValues(alpha: 0.9);
    
    return Container(
      width: 160,
      height: 240,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: suiteColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: suiteColor.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            // 1. 背景纹理
            Positioned.fill(
              child: CustomPaint(
                painter: SuiteTechPainter(c.suite, suiteColor.withValues(alpha: 0.1)),
              ),
            ),
            // 2. 动态扫描线
            Positioned.fill(
              child: IgnorePointer(
                child: CyberScanline(
                  color: suiteColor.withValues(alpha: 0.15),
                  isGlitch: c.suite == CardSuite.overload,
                ),
              ),
            ),
            // 3. 科技感边角装饰
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CyberCornerPainter(color: suiteColor.withValues(alpha: 0.2)),
                ),
              ),
            ),
            // 4. 内容层
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和费用
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (_) {
                            final name = c.name;
                            final base = 16.0;
                            final shrink = name.length > 4 ? (base - (name.length - 4) * 0.8) : base;
                            final titleFont = shrink.clamp(10.0, base);
                            return Text(
                              name,
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: titleFont,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.95),
                                letterSpacing: 1,
                                fontFamily: 'monospace',
                                height: 1.1,
                                shadows: [
                                  Shadow(color: suiteColor.withValues(alpha: 0.5), blurRadius: 4),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF05060A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: suiteColor.withValues(alpha: 0.5), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getSuiteIcon(c.suite),
                              size: 14,
                              color: suiteColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${c.cost}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: suiteColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 标题下方的彩色横线
                  Container(
                    width: double.infinity,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          suiteColor,
                          suiteColor.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 描述文字
                  Expanded(
                    child: _buildCardDescription(c, suiteColor),
                  ),
                  // 底部标识
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Lv${c.level} [${_getTypeName(c.type)}]",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: rarityColor.withValues(alpha: 0.9),
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                      _smallTargetIcon(c.target, suiteColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSuiteIcon(CardSuite suite) {
    switch (suite) {
      case CardSuite.classic: return Icons.bolt_rounded;
      case CardSuite.overload: return Icons.warning_amber_rounded;
      case CardSuite.secure: return Icons.security_rounded;
      case CardSuite.industrial: return Icons.settings_rounded;
      case CardSuite.quantum: return Icons.auto_awesome_rounded;
    }
  }

  Widget _smallTargetIcon(CardTarget target, Color color) {
    IconData icon;
    switch (target) {
      case CardTarget.enemy: icon = Icons.gps_fixed; break;
      case CardTarget.self: icon = Icons.shield; break;
      case CardTarget.all: icon = Icons.grain; break;
    }
    return Icon(icon, size: 16, color: color.withValues(alpha: 0.6));
  }

  Color _getRarityColor(int level) {
    switch (level) {
      case 1: return const Color(0xFF44FF44);
      case 2: return const Color(0xFF6CE4FF);
      case 3: return const Color(0xFFE26CFF);
      case 4: return const Color(0xFFFFD700);
      case 5: return const Color(0xFFFF4444);
      default: return Colors.white70;
    }
  }

  Color _getCardBgColor(CardSuite suite) {
    switch (suite) {
      case CardSuite.overload: return const Color(0xFF1A0A0A);
      case CardSuite.secure: return const Color(0xFF0A1A0A);
      case CardSuite.industrial: return const Color(0xFF1A140A);
      case CardSuite.quantum: return const Color(0xFF140A1A);
      case CardSuite.classic: return const Color(0xFF101722);
    }
  }

  Widget _buildCardDescription(CardData c, Color highlightColor) {
    final text = c.description ?? "";
    if (text.isEmpty) return const SizedBox.shrink();

    const buffKeywords = {'防火墙加固', '算力', '系统修复', '能量', '能量点', '数据包', '带宽'};
    const debuffKeywords = {'虚弱', '脆弱', '漏洞暴露', '恶意代码'};
    const damageKeywords = {'冲击', '自损', '受损'};

    final regex = RegExp(r'(\d+)|(冲击|防火墙加固|数据包|算力|虚弱|脆弱|恶意代码|自损|系统修复|能量|能量点|漏洞暴露|受损|带宽)');
    final List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9),
        ));
      }

      final isNumber = match.group(1) != null;
      final matchText = match.group(0)!;
      bool isBadEffect = false;
      String associatedKeyword = "";
      
      if (isNumber) {
        final afterText = text.substring(match.end, (match.end + 12).clamp(0, text.length));
        final beforeText = text.substring((match.start - 12).clamp(0, text.length), match.start);
        for (var k in [...buffKeywords, ...debuffKeywords, ...damageKeywords]) {
          if (afterText.contains(k) || beforeText.contains(k)) {
            associatedKeyword = k;
            break;
          }
        }
      } else {
        associatedKeyword = matchText;
      }

      CardTarget target = c.target;
      if (associatedKeyword == "自损" || associatedKeyword == "受损") target = CardTarget.self;

      if (damageKeywords.contains(associatedKeyword)) {
        isBadEffect = (target == CardTarget.self);
      } else if (buffKeywords.contains(associatedKeyword)) {
        isBadEffect = (target != CardTarget.self);
      } else if (debuffKeywords.contains(associatedKeyword)) {
        isBadEffect = (target == CardTarget.self);
      }

      Color displayColor = isBadEffect ? const Color(0xFFFF4444) : (isNumber ? Colors.white : highlightColor);

      spans.add(TextSpan(
        text: matchText,
        style: TextStyle(
          color: displayColor,
          fontWeight: (isNumber || isBadEffect) ? FontWeight.w900 : FontWeight.bold,
          fontSize: isNumber ? 11 : 10,
          shadows: [Shadow(color: displayColor.withValues(alpha: 0.6), blurRadius: 4)],
        ),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9),
      ));
    }

    return RichText(
      text: TextSpan(children: spans, style: const TextStyle(fontFamily: 'monospace', height: 1.4)),
    );
  }

  Color _getSuiteColor(CardSuite suite) {
    switch (suite) {
      case CardSuite.classic: return const Color(0xFF6CE4FF);
      case CardSuite.overload: return const Color(0xFFFF4444);
      case CardSuite.secure: return const Color(0xFFC3A6FF);
      case CardSuite.industrial: return const Color(0xFFFFB344);
      case CardSuite.quantum: return const Color(0xFFE26CFF);
    }
  }

  String _getTypeName(CardType type) {
    switch (type) {
      case CardType.exploit: return 'EXPLOIT';
      case CardType.encryption: return 'ENCRYPT';
      case CardType.routine: return 'ROUTINE';
      case CardType.module: return 'MODULE';
    }
  }
}

class _GridPainter extends CustomPainter {
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
