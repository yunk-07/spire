import 'package:flutter/material.dart';
import 'dart:math';
import 'start_screen.dart';
import 'game_state.dart';
import 'level_data.dart';
import 'card_data.dart';
import 'main.dart';
import 'map_screen.dart';

/// 数据缓存站页面 - 允许接入单元同步数据并恢复完整度
class RestPage extends StatefulWidget {
  final String levelId;

  const RestPage({super.key, required this.levelId});

  @override
  State<RestPage> createState() => _RestPageState();
}

class _RestPageState extends State<RestPage> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  int _healAmount = 0;
  bool _showingCardRewards = false;
  List<CardData> _rewardCards = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // 辅助函数：根据卡牌套装(Suite)确定视觉风格
  Color _getSuiteColor(CardSuite suite) {
    switch (suite) {
      case CardSuite.classic: return const Color(0xFF6CE4FF);
      case CardSuite.overload: return const Color(0xFFFF4444);
      case CardSuite.secure: return const Color(0xFF44FF44);
      case CardSuite.industrial: return const Color(0xFFFFB344);
      case CardSuite.quantum: return const Color(0xFFE26CFF);
    }
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

  IconData _getSuiteIcon(CardSuite suite) {
    switch (suite) {
      case CardSuite.classic: return Icons.bolt_rounded;
      case CardSuite.overload: return Icons.warning_amber_rounded;
      case CardSuite.secure: return Icons.security_rounded;
      case CardSuite.industrial: return Icons.settings_rounded;
      case CardSuite.quantum: return Icons.auto_awesome_rounded;
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
          style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 8),
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
          fontSize: isNumber ? 10 : 9,
          shadows: [Shadow(color: displayColor.withValues(alpha: 0.6), blurRadius: 4)],
        ),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 8),
      ));
    }

    return RichText(
      text: TextSpan(children: spans, style: const TextStyle(fontFamily: 'monospace', height: 1.3)),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _smallTargetIcon(CardTarget target, Color color) {
    IconData icon;
    switch (target) {
      case CardTarget.enemy: icon = Icons.gps_fixed; break;
      case CardTarget.self: icon = Icons.shield; break;
      case CardTarget.all: icon = Icons.grain; break;
    }
    return Icon(icon, size: 10, color: color.withValues(alpha: 0.6));
  }

  Widget _cardWidget(CardData c) {
    final suiteColor = _getSuiteColor(c.suite);
    final rarityColor = _getRarityColor(c.level);
    
    Color getCardBgColor() {
      switch (c.suite) {
        case CardSuite.overload: return const Color(0xFF1A0A0A);
        case CardSuite.secure: return const Color(0xFF0A1A0A);
        case CardSuite.industrial: return const Color(0xFF1A140A);
        case CardSuite.quantum: return const Color(0xFF140A1A);
        case CardSuite.classic: return const Color(0xFF101722);
      }
    }
    
    final cardBgColor = getCardBgColor().withValues(alpha: 0.9);
    
    return Container(
      width: 100,
      height: 140,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: suiteColor.withValues(alpha: 0.6), width: 1.0),
        boxShadow: [
          BoxShadow(color: suiteColor.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1),
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(2, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: SuiteTechPainter(c.suite, suiteColor.withValues(alpha: 0.1)),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CyberScanline(
                  color: suiteColor.withValues(alpha: 0.15),
                  isGlitch: c.suite == CardSuite.overload,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CyberCornerPainter(color: suiteColor.withValues(alpha: 0.15)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.95),
                            letterSpacing: 0.5,
                            fontFamily: 'monospace',
                            shadows: [Shadow(color: suiteColor.withValues(alpha: 0.5), blurRadius: 4)],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF05060A),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: suiteColor.withValues(alpha: 0.5), width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(_getSuiteIcon(c.suite), size: 8, color: suiteColor),
                            Text(
                              "${c.cost}",
                              style: TextStyle(
                                fontSize: 10,
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
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [suiteColor, suiteColor.withValues(alpha: 0.2)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(child: _buildCardDescription(c, suiteColor)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Lv${c.level}",
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: rarityColor.withValues(alpha: 0.9),
                          fontFamily: 'monospace',
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

  void _generateRandomCard() {
    final random = Random();
    final allCards = cardDatabase.values.toList();
    
    // 随机抽取3张不重复的卡牌
    final List<CardData> pickedCards = [];
    final availableCards = List<CardData>.from(allCards);
    
    for (int i = 0; i < 3 && availableCards.isNotEmpty; i++) {
      final index = random.nextInt(availableCards.length);
      pickedCards.add(availableCards.removeAt(index));
    }

    setState(() {
      _rewardCards = pickedCards;
      _showingCardRewards = true;
    });
  }

  void _onSelectCard(CardData card) {
    // 将选中的卡牌加入抽牌堆
    GameState.drawPile.add(card.id);
    
    // 标记该缓存站已使用
    GameProgress.markDefeated(widget.levelId);
    
    if (mounted) {
      CyberToast.show(context, '同步完成：已获取新指令集 [${card.name}]');
      Navigator.pushReplacement(
        context,
        createHoloRoute(
          const MapScreen(
            canReturnToGame: true,
            canSelect: true,
          ),
        ),
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
          // 返回到开始页面（根路由）
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        body: Stack(
          children: [
            // 关键区域：统一背景美化
            const Positioned.fill(
              child: CyberBackground(),
            ),
            FadeTransition(
              opacity: _fadeController,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _showingCardRewards ? _buildCardRewardView() : _buildInitialView(),
                ),
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
                  // 内部扫描线
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
                        '检测到非正常断开指令。退出将丢失本次数据同步机会，是否确认中断接入？',
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
                            label: '强制中断',
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
    return res ?? false;
  }

  Widget _buildInitialView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 顶部图标与标题
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF6CE4FF).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF6CE4FF).withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF6CE4FF).withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: const Icon(Icons.hub_outlined, color: Color(0xFF6CE4FF), size: 48),
        ),
        const SizedBox(height: 32),
        
        const Text(
          '数据缓存站',
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
          'DATA CACHE STATION v2.1',
          style: TextStyle(
            fontSize: 10,
            color: Color(0x666CE4FF),
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 48),
        
        // 当前状态显示
        Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F16).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFF6CE4FF).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: CyberCornerPainter(color: const Color(0x996CE4FF)),
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(color: Color(0xFF6CE4FF), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'UNIT_INTEGRITY_STATUS',
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFF6CE4FF),
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(color: Color(0xFF6CE4FF), shape: BoxShape.circle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(Icons.favorite, color: Color(0xFFFF6A6A), size: 18),
                      const SizedBox(width: 12),
                      Text(
                        '${GameState.playerHp}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE1E9FF),
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        ' / ${GameState.playerMaxHp}',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFFE1E9FF).withValues(alpha: 0.5),
                          fontFamily: 'monospace',
                          height: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        
        // 选项容器
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              _optionButton(
                icon: Icons.flash_on,
                title: '执行底层修复',
                description: '恢复 20 点系统完整度',
                onTap: _onRest,
              ),
              const SizedBox(height: 16),
              _optionButton(
                icon: Icons.downloading,
                title: '下载指令包',
                description: '从缓存中随机提取一个新指令',
                onTap: _generateRandomCard,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _optionButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF6CE4FF).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6CE4FF).withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 内部动态扫描线
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: const CyberScanline(color: Color(0x336CE4FF)),
              ),
            ),
            // 装饰边角
            Positioned.fill(
              child: CustomPaint(
                painter: CyberCornerPainter(color: const Color(0x666CE4FF)),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6CE4FF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF6CE4FF), size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFFE1E9FF).withValues(alpha: 0.7),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF6CE4FF)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRewardView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 装饰图标
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6CE4FF).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF6CE4FF).withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.downloading, color: Color(0xFF6CE4FF), size: 40),
        ),
        const SizedBox(height: 32),
        
        const Text(
          'CACHE_EXTRACT_COMPLETE',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFF6CE4FF),
            letterSpacing: 4,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '指令集提取完成',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
            shadows: [
              Shadow(color: Color(0xFF6CE4FF), blurRadius: 15),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '请选择一个指令集同步到主内存',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFFE1E9FF).withValues(alpha: 0.6),
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 48),
        
        // 卡牌列表
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F16).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.symmetric(
              horizontal: BorderSide(color: const Color(0xFF6CE4FF).withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _rewardCards.map((card) => _rewardCardWidget(card)).toList(),
          ),
        ),
        
        const SizedBox(height: 64),
        
        // 底部装饰信息
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 12, color: Color(0xFF8FA3C0)),
            const SizedBox(width: 8),
            Text(
              '注意：同步完成后当前缓存站将永久关闭',
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFF8FA3C0).withValues(alpha: 0.8),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onRest() {
    // 恢复20点完整度
    final oldHp = GameState.playerHp;
    GameState.heal(20);
    final newHp = GameState.playerHp;
    _healAmount = newHp - oldHp;
    
    // 标记该缓存站已使用
    GameProgress.markDefeated(widget.levelId);
    
    // 显示同步成功动画和消息
    if (mounted) {
      CyberToast.show(context, '同步完成：修复了 $_healAmount 点完整度');
      Navigator.pushReplacement(
        context,
        createHoloRoute(
          const MapScreen(
            canReturnToGame: true,
            canSelect: true,
          ),
        ),
      );
    }
  }

  Widget _rewardCardWidget(CardData card) {
    return GestureDetector(
      onTap: () => _onSelectCard(card),
      child: _cardWidget(card),
    );
  }
}

// 套装背景画笔：为不同套装提供独特的背景纹理
class SuiteTechPainter extends CustomPainter {
  final CardSuite suite;
  final Color color;
  SuiteTechPainter(this.suite, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    switch (suite) {
      case CardSuite.classic:
        // 经典：平行的 45 度斜线
        for (double i = -size.height; i < size.width; i += 15) {
          canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
        }
        break;
      case CardSuite.overload:
        // 过载：不规则的水平短促故障线
        final random = Random(42);
        for (int i = 0; i < 15; i++) {
          final y = random.nextDouble() * size.height;
          final x = random.nextDouble() * size.width;
          final len = random.nextDouble() * 20 + 5;
          canvas.drawLine(Offset(x, y), Offset(x + len, y), paint..strokeWidth = 1.0);
        }
        break;
      case CardSuite.secure:
        // 矩阵：垂直的虚线
        for (double x = 5; x < size.width; x += 12) {
          for (double y = 0; y < size.height; y += 8) {
            if ((x + y) % 16 < 8) {
              canvas.drawCircle(Offset(x, y), 0.5, paint);
            }
          }
        }
        break;
      case CardSuite.industrial:
        // 工业：交叉的网格
        for (double i = 0; i < size.width; i += 15) {
          canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
        }
        for (double i = 0; i < size.height; i += 15) {
          canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
        }
        break;
      case CardSuite.quantum:
        // 量子：同心圆弧片段
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(size.width * 0.8, size.height * 0.2),
            20.0 + i * 15,
            paint..style = PaintingStyle.stroke,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

