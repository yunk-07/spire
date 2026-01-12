import 'package:flutter/material.dart';
import 'dart:math';
import 'start_screen.dart';
import 'game_state.dart';
import 'level_data.dart';
import 'card_data.dart';

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

  void _generateCardRewards() {
    final random = Random();
    final allCards = cardDatabase.values.toList();
    final List<CardData> rewards = [];
    
    // 随机抽取3张不重复的卡牌
    while (rewards.length < 3 && rewards.length < allCards.length) {
      final card = allCards[random.nextInt(allCards.length)];
      if (!rewards.contains(card)) {
        rewards.add(card);
      }
    }
    
    setState(() {
      _rewardCards = rewards;
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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  Widget _buildInitialView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 标题
        const Text(
          '数据缓存站',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6CE4FF),
            letterSpacing: 8,
            fontFamily: 'monospace',
            shadows: [
              Shadow(color: Color(0xFF6CE4FF), blurRadius: 15),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'DATA CACHE STATION v2.0',
          style: TextStyle(
            fontSize: 10,
            color: Color(0x666CE4FF),
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 24),
        
        // 分隔线
        Container(
          width: 150,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xFF6CE4FF),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),
        
        // 当前状态显示
        Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F16).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFF6CE4FF).withValues(alpha: 0.3),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: CyberCornerPainter(color: const Color(0x666CE4FF)),
                ),
              ),
              Column(
                children: [
                  const Text(
                    'ACCESS UNIT STATUS',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8FA3C0),
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite, color: Color(0xFFFF6A6A), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'HP: ${GameState.playerHp}/${GameState.playerMaxHp}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE1E9FF),
                          fontFamily: 'monospace',
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
        
        // 选项 1: 恢复
        _optionButton(
          icon: Icons.flash_on,
          title: '执行底层修复',
          description: '恢复 20 点系统完整度',
          onTap: _onRest,
        ),
        
        const SizedBox(height: 20),
        
        // 选项 2: 获取卡牌
        _optionButton(
          icon: Icons.downloading,
          title: '下载指令包',
          description: '从缓存中提取新的操作指令',
          onTap: _generateCardRewards,
        ),
        
        const SizedBox(height: 48),
        
        // 离开按钮
        CyberButton(
          label: '取消接入',
          width: 160,
          height: 40,
          fontSize: 12,
          color: const Color(0xFF8FA3C0),
          onPressed: () => Navigator.pop(context),
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
        const Text(
          '提取完成',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6CE4FF),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '请选择要同步到主内存的指令集',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFFE1E9FF).withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 48),
        
        // 卡牌列表
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _rewardCards.map((card) => _rewardCardWidget(card)).toList(),
        ),
        
        const SizedBox(height: 64),
        
        CyberButton(
          label: '返回选项',
          width: 160,
          height: 40,
          fontSize: 12,
          color: const Color(0xFF8FA3C0),
          onPressed: () {
            setState(() {
              _showingCardRewards = false;
            });
          },
        ),
      ],
    );
  }

  Widget _rewardCardWidget(CardData card) {
    Color getRarityColor() {
      switch (card.level) {
        case 1: return const Color(0xFF6CE4FF);
        case 2: return const Color(0xFF44FF44);
        case 3: return const Color(0xFFE26CFF);
        default: return Colors.white70;
      }
    }
    
    final color = getRarityColor();
    
    return GestureDetector(
      onTap: () => _onSelectCard(card),
      child: Container(
        width: 110,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 内部扫描线
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: CyberScanline(color: color.withValues(alpha: 0.1)),
              ),
            ),
            // 装饰边角
            Positioned.fill(
              child: CustomPaint(
                painter: CyberCornerPainter(
                  color: color.withValues(alpha: 0.4),
                  cornerSize: 12,
                ),
              ),
            ),
            // 内容
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'monospace',
                            shadows: [Shadow(color: color, blurRadius: 4)],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF05060A),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
                        ),
                        child: Text(
                          "${card.cost}",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: color,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(height: 1, color: color.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      card.description ?? "",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 9,
                        fontFamily: 'monospace',
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.type.name.toUpperCase(),
                        style: TextStyle(
                          color: color.withValues(alpha: 0.6),
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                      Icon(Icons.bolt, color: color.withValues(alpha: 0.6), size: 10),
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
      Navigator.pop(context);
    }
  }
}

