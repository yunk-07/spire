import 'package:flutter/material.dart';
import 'dart:math';
import 'game_state.dart';
import 'level_data.dart';
import 'card_data.dart';
import 'main.dart';
import 'map_screen.dart';
import 'theme_config.dart';

/// 数据缓存站页面 - 允许接入单元同步数据并恢复完整度
class RestPage extends StatefulWidget {
  final LevelInfo? level;

  const RestPage({super.key, this.level});

  @override
  State<RestPage> createState() => _RestPageState();
}

class _RestPageState extends State<RestPage> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  int _healAmount = 0;
  bool _showingCardRewards = false;
  List<CardData> _rewardCards = [];

  LevelInfo? get node => widget.level;
  String get levelId => node?.id ?? 'UNKNOWN';
  String get levelTitle => node?.title ?? '缓存站';

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

  void _generateRandomCard() {
    final random = Random();
    // 关键区域：排除恶魔和神圣系列卡牌（仅限Boss奖励）
    final allCards = cardDatabase.values.where((c) => c.suite != CardSuite.demon && c.suite != CardSuite.holy).toList();
    
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
    GameProgress.markDefeated(levelId);
    
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

  void _onUpgradeStrength() {
    GameState.permanentStrength += 1;
    GameProgress.markDefeated(levelId);
    if (mounted) {
      CyberToast.show(context, '系统升级：永久算力 +1');
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

  void _onUpgradeBlock() {
    GameState.permanentBlock += 2;
    GameProgress.markDefeated(levelId);
    if (mounted) {
      CyberToast.show(context, '系统升级：永久防火墙 +2');
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
        final shouldExit = await showCyberConfirmExit(context);
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: _showingCardRewards ? _buildCardRewardView() : _buildInitialView(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    final themeColor = GameState.getThemeColor();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 顶部图标与标题
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: themeColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: themeColor.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Icon(Icons.hub_outlined, color: themeColor, size: 48),
        ),
        const SizedBox(height: 32),
        
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
          'DATA CACHE STATION v2.1',
          style: TextStyle(
            fontSize: 10,
            color: themeColor.withValues(alpha: 0.4),
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 12),
        _metaRow(themeColor),
        const SizedBox(height: 48),
        
        // 当前状态显示
        Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F16).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.3),
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
                  painter: CyberCornerPainter(color: themeColor.withValues(alpha: 0.6)),
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
                        decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'UNIT_INTEGRITY_STATUS',
                        style: TextStyle(
                          fontSize: 9,
                          color: themeColor,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
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
                description: '恢复 20 点生命',
                onTap: _onRest,
              ),
              const SizedBox(height: 16),
              _optionButton(
                icon: Icons.add_moderator,
                title: '永久增加防火墙',
                description: '基础护盾永久增加 2 点',
                onTap: _onUpgradeBlock,
              ),
              const SizedBox(height: 16),
              _optionButton(
                icon: Icons.trending_up,
                title: '永久提升算力',
                description: '基础攻击伤害永久增加 1 点',
                onTap: _onUpgradeStrength,
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
    final themeColor = GameState.getThemeColor();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: themeColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.2),
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
                child: CyberScanline(color: themeColor.withValues(alpha: 0.2)),
              ),
            ),
            // 装饰边角
            Positioned.fill(
              child: CustomPaint(
                painter: CyberCornerPainter(color: themeColor.withValues(alpha: 0.4)),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: themeColor, size: 24),
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
                Icon(Icons.chevron_right, color: themeColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRewardView() {
    final themeColor = GameState.getThemeColor();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 装饰图标
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: themeColor.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.downloading, color: themeColor, size: 40),
        ),
        const SizedBox(height: 32),
        
        Text(
          'CACHE_EXTRACT_COMPLETE',
          style: TextStyle(
            fontSize: 10,
            color: themeColor,
            letterSpacing: 4,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '指令集提取完成',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
            shadows: [
              Shadow(color: themeColor, blurRadius: 15),
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
              horizontal: BorderSide(color: themeColor.withValues(alpha: 0.1)),
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
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.hub_outlined, size: 12, color: color),
                const SizedBox(width: 6),
                const Text(
                  "OPTIONS: 2",
                  style: TextStyle(
                    color: Colors.white70,
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
                  style: const TextStyle(
                    color: Colors.white70,
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

  void _onRest() {
    // 恢复20点完整度
    final oldHp = GameState.playerHp;
    GameState.heal(20);
    final newHp = GameState.playerHp;
    _healAmount = newHp - oldHp;
    
    // 标记该缓存站已使用
    GameProgress.markDefeated(levelId);
    
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
      child: ThemeConfig.buildCardWidget(card, width: 100, height: 140),
    );
  }
}
