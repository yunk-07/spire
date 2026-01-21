// exchange_page.dart
// 作用：提供数据交易所界面，玩家可以在此选择并获得新的卡牌

import 'package:flutter/material.dart';
import 'game_state.dart';
import 'card_data.dart';
import 'main.dart' hide createHoloRoute;
import 'core/route.dart' show createHoloRoute;
import 'start_screen.dart';
import 'map_screen.dart';

class ExchangePage extends StatefulWidget {
  final String? levelId;
  const ExchangePage({super.key, this.levelId});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  bool _hasChosen = false;

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
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _GridPainter(),
                ),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _metaRow(),
                  const SizedBox(height: 8),
                  _hpRow(),
                  const SizedBox(height: 48),
                  Expanded(
                    child: Center(
                      child: _logicPanel(_buildLogicExchangeOptions()),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Text(
                        '请选择一个逻辑交易项以继续...',
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

  Widget _metaRow() {
    final color = const Color(0xFF6CE4FF);
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
                  "NODE: ${widget.levelId ?? 'UNKNOWN'}",
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

  Widget _hpRow() {
    final color = const Color(0xFF6CE4FF);
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
          '逻辑交易所',
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
          'LOGIC EXCHANGE PROTOCOL v3.4',
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

  Widget _buildLogicExchangeOptions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _optionTile(
            label: "恢复已损失生命的 50%",
            icon: Icons.healing,
            color: const Color(0xFF6CE4FF),
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

  Widget _logicPanel(Widget child) {
    final color = const Color(0xFF6CE4FF);
    return RepaintBoundary(
      child: Container(
      width: 620,
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
                    Icon(Icons.memory, size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(
                      "// LOGIC_CHANNEL",
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
                border: Border.all(color: const Color(0xFF6CE4FF).withValues(alpha: 0.7)),
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
                                        border: Border.all(color: const Color(0xFF6CE4FF).withValues(alpha: 0.2)),
                                      ),
                                      child: Text(id, style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace')),
                                    );
                                  }
                                  return GestureDetector(
                                    onTap: () => Navigator.pop(ctx, id),
                                    child: gameCardWidget(data),
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
                  CyberButton(label: '取消', onPressed: () => Navigator.pop(ctx, null), width: 120, height: 40, fontSize: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget gameCardWidget(CardData c, {VoidCallback? onTap}) {
    final suiteColor = getSuiteColor(c.suite);
    final rarityColor = getRarityColor(c.level);
    final cardBgColor = getCardBgColor(c.suite).withValues(alpha: 0.9);
    final content = RepaintBoundary(
      child: Container(
      width: 160,
      height: 240,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: suiteColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [BoxShadow(color: suiteColor.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 2), BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(3, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: SuiteTechPainter(c.suite, suiteColor.withValues(alpha: 0.1)))),
            Positioned.fill(child: IgnorePointer(child: CyberScanline(color: suiteColor.withValues(alpha: 0.15), isGlitch: c.suite == CardSuite.overload))),
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: CyberCornerPainter(color: suiteColor.withValues(alpha: 0.2))))),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: titleFont,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.95),
                                letterSpacing: 1,
                                fontFamily: 'monospace',
                                height: 1.1,
                                shadows: [Shadow(color: suiteColor.withValues(alpha: 0.5), blurRadius: 4)],
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF05060A), borderRadius: BorderRadius.circular(4), border: Border.all(color: suiteColor.withValues(alpha: 0.5), width: 1)),
                        child: Row(
                          children: [
                            Icon(getSuiteIcon(c.suite), size: 14, color: suiteColor),
                            const SizedBox(width: 4),
                            Text("${c.cost}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: suiteColor, fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 2,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [suiteColor, suiteColor.withValues(alpha: 0.2)])),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: buildCardDescription(c, suiteColor)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Lv${c.level} [${getTypeName(c.type)}]", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: rarityColor.withValues(alpha: 0.9), fontFamily: 'monospace', letterSpacing: 1)),
                      smallTargetIcon(c.target, suiteColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: content) : content;
  }

  IconData getSuiteIcon(CardSuite suite) {
    switch (suite) {
      case CardSuite.classic: return Icons.bolt_rounded;
      case CardSuite.overload: return Icons.warning_amber_rounded;
      case CardSuite.secure: return Icons.security_rounded;
      case CardSuite.industrial: return Icons.settings_rounded;
      case CardSuite.quantum: return Icons.auto_awesome_rounded;
    }
  }

  Widget smallTargetIcon(CardTarget target, Color color) {
    IconData icon;
    switch (target) {
      case CardTarget.enemy: icon = Icons.gps_fixed; break;
      case CardTarget.self: icon = Icons.shield; break;
      case CardTarget.all: icon = Icons.grain; break;
    }
    return Icon(icon, size: 16, color: color.withValues(alpha: 0.6));
  }

  Color getRarityColor(int level) {
    switch (level) {
      case 1: return const Color(0xFF44FF44);
      case 2: return const Color(0xFF6CE4FF);
      case 3: return const Color(0xFFE26CFF);
      case 4: return const Color(0xFFFFD700);
      case 5: return const Color(0xFFFF4444);
      default: return Colors.white70;
    }
  }

  Color getCardBgColor(CardSuite suite) {
    switch (suite) {
      case CardSuite.overload: return const Color(0xFF1A0A0A);
      case CardSuite.secure: return const Color(0xFF0A1A0A);
      case CardSuite.industrial: return const Color(0xFF1A140A);
      case CardSuite.quantum: return const Color(0xFF140A1A);
      case CardSuite.classic: return const Color(0xFF101722);
    }
  }

  Widget buildCardDescription(CardData c, Color highlightColor) {
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

  Color getSuiteColor(CardSuite suite) {
    switch (suite) {
      case CardSuite.classic: return const Color(0xFF6CE4FF);
      case CardSuite.overload: return const Color(0xFFFF4444);
      case CardSuite.secure: return const Color(0xFFC3A6FF);
      case CardSuite.industrial: return const Color(0xFFFFB344);
      case CardSuite.quantum: return const Color(0xFFE26CFF);
    }
  }

  String getTypeName(CardType type) {
    switch (type) {
      case CardType.exploit: return 'EXPLOIT';
      case CardType.encryption: return 'ENCRYPT';
      case CardType.routine: return 'ROUTINE';
      case CardType.module: return 'MODULE';
    }
  }
}

Widget gameCardWidget(CardData c, {VoidCallback? onTap}) {
  final suiteColor = getSuiteColor(c.suite);
  final rarityColor = getRarityColor(c.level);
  final cardBgColor = getCardBgColor(c.suite).withValues(alpha: 0.9);
  final content = Container(
    width: 160,
    height: 240,
    decoration: BoxDecoration(
      color: cardBgColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: suiteColor.withValues(alpha: 0.6), width: 1.5),
      boxShadow: [BoxShadow(color: suiteColor.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 2), BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(3, 3))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: SuiteTechPainter(c.suite, suiteColor.withValues(alpha: 0.1)))),
          Positioned.fill(child: IgnorePointer(child: CyberScanline(color: suiteColor.withValues(alpha: 0.15), isGlitch: c.suite == CardSuite.overload))),
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: CyberCornerPainter(color: suiteColor.withValues(alpha: 0.2))))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              shadows: [Shadow(color: suiteColor.withValues(alpha: 0.5), blurRadius: 4)],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF05060A), borderRadius: BorderRadius.circular(4), border: Border.all(color: suiteColor.withValues(alpha: 0.5), width: 1)),
                      child: Row(
                        children: [
                          Icon(getSuiteIcon(c.suite), size: 14, color: suiteColor),
                          const SizedBox(width: 4),
                          Text("${c.cost}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: suiteColor, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 2,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [suiteColor, suiteColor.withValues(alpha: 0.2)])),
                ),
                const SizedBox(height: 8),
                Expanded(child: buildCardDescription(c, suiteColor)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Lv${c.level} [${getTypeName(c.type)}]", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: rarityColor.withValues(alpha: 0.9), fontFamily: 'monospace', letterSpacing: 1)),
                    smallTargetIcon(c.target, suiteColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  return onTap != null ? GestureDetector(onTap: onTap, child: content) : content;
}

IconData getSuiteIcon(CardSuite suite) {
  switch (suite) {
    case CardSuite.classic: return Icons.bolt_rounded;
    case CardSuite.overload: return Icons.warning_amber_rounded;
    case CardSuite.secure: return Icons.security_rounded;
    case CardSuite.industrial: return Icons.settings_rounded;
    case CardSuite.quantum: return Icons.auto_awesome_rounded;
  }
}

Widget smallTargetIcon(CardTarget target, Color color) {
  IconData icon;
  switch (target) {
    case CardTarget.enemy: icon = Icons.gps_fixed; break;
    case CardTarget.self: icon = Icons.shield; break;
    case CardTarget.all: icon = Icons.grain; break;
  }
  return Icon(icon, size: 16, color: color.withValues(alpha: 0.6));
}

Color getRarityColor(int level) {
  switch (level) {
    case 1: return const Color(0xFF44FF44);
    case 2: return const Color(0xFF6CE4FF);
    case 3: return const Color(0xFFE26CFF);
    case 4: return const Color(0xFFFFD700);
    case 5: return const Color(0xFFFF4444);
    default: return Colors.white70;
  }
}

Color getCardBgColor(CardSuite suite) {
  switch (suite) {
    case CardSuite.overload: return const Color(0xFF1A0A0A);
    case CardSuite.secure: return const Color(0xFF0A1A0A);
    case CardSuite.industrial: return const Color(0xFF1A140A);
    case CardSuite.quantum: return const Color(0xFF140A1A);
    case CardSuite.classic: return const Color(0xFF101722);
  }
}

final Map<String, List<InlineSpan>> _descCache = {};

Widget buildCardDescription(CardData c, Color highlightColor) {
  final text = c.description ?? "";
  if (text.isEmpty) return const SizedBox.shrink();
  final key = '${c.id}|$text';
  final cached = _descCache[key];
  if (cached != null) {
    return Text.rich(
      TextSpan(children: cached, style: const TextStyle(fontFamily: 'monospace', height: 1.4)),
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
    );
  }
  const buffKeywords = {'防火墙加固', '算力', '系统修复', '能量', '能量点', '数据包', '带宽'};
  const debuffKeywords = {'虚弱', '脆弱', '漏洞暴露', '恶意代码'};
  const damageKeywords = {'冲击', '自损', '受损'};
  final regex = RegExp(r'(\d+)|(冲击|防火墙加固|数据包|算力|虚弱|脆弱|恶意代码|自损|系统修复|能量|能量点|漏洞暴露|受损|带宽)');
  final List<TextSpan> spans = [];
  int lastMatchEnd = 0;
  for (final match in regex.allMatches(text)) {
    if (match.start > lastMatchEnd) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9)));
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
    spans.add(TextSpan(text: matchText, style: TextStyle(color: displayColor, fontWeight: (isNumber || isBadEffect) ? FontWeight.w900 : FontWeight.bold, fontSize: isNumber ? 11 : 10, shadows: [Shadow(color: displayColor.withValues(alpha: 0.6), blurRadius: 4)])));
    lastMatchEnd = match.end;
  }
  if (lastMatchEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastMatchEnd), style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9)));
  }
  _descCache[key] = spans;
  return Text.rich(
    TextSpan(children: spans, style: const TextStyle(fontFamily: 'monospace', height: 1.4)),
    maxLines: 5,
    overflow: TextOverflow.ellipsis,
    softWrap: true,
  );
}

Color getSuiteColor(CardSuite suite) {
  switch (suite) {
    case CardSuite.classic: return const Color(0xFF6CE4FF);
    case CardSuite.overload: return const Color(0xFFFF4444);
    case CardSuite.secure: return const Color(0xFFC3A6FF);
    case CardSuite.industrial: return const Color(0xFFFFB344);
    case CardSuite.quantum: return const Color(0xFFE26CFF);
  }
}

String getTypeName(CardType type) {
  switch (type) {
    case CardType.exploit: return 'EXPLOIT';
    case CardType.encryption: return 'ENCRYPT';
    case CardType.routine: return 'ROUTINE';
    case CardType.module: return 'MODULE';
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
