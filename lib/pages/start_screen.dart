import 'package:flutter/material.dart';
import '../models/character_data.dart';
import '../models/card_data.dart';
import '../models/level_data.dart';
// import 'brainchip_data.dart';
import '../main.dart';
import 'brainchip_selection_screen.dart';
import '../core/tower_painter.dart';
import '../models/game_state.dart';
import '../config/theme_config.dart';

List<double> _buildRadarData(CharacterData c) {
  double gain = 0; // strength/temp_strength/sturdy/max_hp_up
  double drawEaseSum = 0; // ease-of-trigger weighted count of draw cards
  double tempo = 0; // energy/heal
  double survival = 0; // block/heal
  double deckLvAvg = 0;
  int countLv = 0;
  for (final id in c.startingDeck) {
    final card = cardDatabase[id];
    if (card == null) continue;
    final eff = (card.effect ?? '').toLowerCase();
    for (final seg in eff.split(';')) {
      final t = seg.trim().split(RegExp(r'\s+'));
      if (t.isEmpty) continue;
      final key = t[0];
      final val = t.length > 1 ? double.tryParse(t[1]) ?? 0 : 0;
      if (key == 'strength' || key == 'temp_strength' || key == 'sturdy' || key == 'max_hp_up') {
        double w = 1;
        if (key == 'temp_strength') w = 0.25;
        if (key == 'sturdy') w = 0.3;
        gain += val * w;
      } else if (key == 'draw') {
        double ease = 1.0;
        if (card.cost == 0) ease = 1.2;
        else if (card.cost <= 1) ease = 1.0;
        else ease = 0.5;
        drawEaseSum += ease;
      } else if (key == 'energy' || key == 'heal') {
        tempo += val;
      } else if (key == 'block' || key == 'heal') {
        double w = key == 'block' ? 0.1 : 1.0;
        survival += val * w;
      }
    }
    deckLvAvg += card.level.toDouble();
    countLv++;
  }
  final deck = countLv > 0 ? (deckLvAvg / countLv) / 5.0 : 0.0;
  final draw = countLv > 0 ? (drawEaseSum / countLv) : 0.0;
  const baseline = 0.2;
  double scale(double v) => (v * 2).clamp(baseline, 1.0);
  final gainN = scale((gain / 12.0).clamp(0.0, 1.0));
  final drawN = scale((draw / 12.0).clamp(0.0, 1.0));
  final tempoN = scale((tempo / 12.0).clamp(0.0, 1.0));
  final survivalN = scale((survival / 12.0).clamp(0.0, 1.0));
  final deckN = scale(deck.clamp(0.0, 1.0));
  return [gainN, drawN, tempoN, survivalN, deckN];
}

/// 开始页面 - 欢迎界面
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 关键区域：背景美化
          const Positioned.fill(
            child: CyberBackground(),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.35,
                child: RepaintBoundary(child: const HoloTowerWidget()),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 游戏标题：增强科幻感
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 底层发光阴影
                    Text(
                      'SPIRE',
                      style: TextStyle(
                        fontSize: 62,
                        fontWeight: FontWeight.w900,
                        color: GameState.getThemeColor().withValues(alpha: 0.2),
                        letterSpacing: 10.0,
                        fontFamily: 'monospace',
                      ),
                    ),
                    // 主文字
                    Text(
                      'SPIRE',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: GameState.getThemeColor(),
                        letterSpacing: 8.0,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(
                            color: GameState.getThemeColor().withValues(alpha: 0.8),
                            blurRadius: 20,
                          ),
                          Shadow(
                            color: GameState.getThemeColor(),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 游戏副标题：HUD 装饰风格
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: GameState.getThemeColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DATA WORLD INFILTRATION SYSTEM',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8FA3C0),
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: GameState.getThemeColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // 开始游戏按钮
                CyberButton(
                  heroTag: 'main_action_button',
                  label: '初始化接入序列',
                  onPressed: () {
                    Navigator.push(
                      context,
                      createHoloRoute(const CharacterSelectScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 游戏说明
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: const Text(
                    '选择接入单元，上传记忆与战术模块，执行高塔渗透任务。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF5D708A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 角色选择页面
class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen>
    with TickerProviderStateMixin {
  String? selectedCharacterId;
  String? _animatingCharacterId;
  final Map<String, AnimationController> _animationControllers = {};
  bool _radarExpanded = false;

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    super.dispose();
  }

  void _startAnimation(String characterId) {
    // 1. 彻底清理现有的动画控制器，防止内存泄漏和竞争
    for (var controller in _animationControllers.values) {
      try {
        controller.stop();
        controller.dispose();
      } catch (_) {
        // 忽略已释放或正在释放的控制器的异常
      }
    }
    _animationControllers.clear();

    // 2. 创建新的动画控制器
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _animationControllers[characterId] = controller;
    
    // 3. 动画完成后安全清理
    controller.forward().then((_) {
      if (mounted && _animationControllers[characterId] == controller) {
        _animationControllers.remove(characterId);
        try {
          controller.dispose();
        } catch (_) {}
        setState(() {
          if (_animatingCharacterId == characterId) {
            _animatingCharacterId = null;
          }
        });
      }
    }).catchError((_) {
      // 捕获动画过程中可能产生的异常（例如被dispose）
    });

    setState(() {
      _animatingCharacterId = characterId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showCyberConfirmExit(context);
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 关键区域：背景美化
            const Positioned.fill(
              child: CyberBackground(),
            ),
            // 职业背景动效
            if (selectedCharacterId != null)
              Positioned.fill(
                child: CyberClassSpecialEffect(
                  characterClass: characterDatabase[selectedCharacterId!]!.characterClass,
                ),
              ),
            Column(
              children: [
                // 自定义美化标题栏
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF101722).withValues(alpha: 0.95),
                        const Color(0xFF0A0F16).withValues(alpha: 0.0),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: GameState.getThemeColor().withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: GameState.getThemeColor(),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(1),
                                    bottomRight: Radius.circular(3),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "// SYSTEM.NEURAL_LINK // ACTIVE",
                                style: TextStyle(
                                  color: GameState.getThemeColor().withValues(alpha: 0.5),
                                  fontSize: 8,
                                  letterSpacing: 1.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "ID_SCAN: OK",
                            style: TextStyle(
                              color: GameState.getThemeColor().withValues(alpha: 0.3),
                              fontSize: 8,
                              letterSpacing: 1.0,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '配置接入单元',
                            style: TextStyle(
                              color: GameState.getThemeColor().withValues(alpha: 0.1),
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              letterSpacing: 4,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2, left: 2),
                            child: Text(
                              '配置接入单元',
                              style: TextStyle(
                                color: const Color(0xFFE1E9FF),
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: 4,
                                shadows: [
                                  Shadow(
                                    color: GameState.getThemeColor().withValues(alpha: 0.5),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              // 角色选择说明
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '选择渗透载体',
                      style: TextStyle(
                        fontSize: 11, 
                        color: Color(0xFF8FA3C0),
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(width: 20, height: 1, color: Colors.white12),
                    const SizedBox(width: 10),
                    const Text(
                      '同步战术算法',
                      style: TextStyle(
                        fontSize: 11, 
                        color: Color(0xFF8FA3C0),
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 角色列表
              Expanded(
                child: ListView.builder(
                  itemCount: characterDatabase.length,
                  itemBuilder: (context, index) {
                    final character = characterDatabase.values.elementAt(index);
                    final isSelected = selectedCharacterId == character.id;

                    return GestureDetector(
                      onTap: () {
                        if (selectedCharacterId == character.id) {
                          setState(() {
                            _radarExpanded = !_radarExpanded;
                          });
                        } else {
                          setState(() {
                            selectedCharacterId = character.id;
                            _radarExpanded = true;
                          });
                          _startAnimation(character.id);
                        }
                      },
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 160),
                        scale: isSelected ? 1.02 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF0A0F16).withValues(alpha: 0.9),
                                const Color(0xFF1A1F26).withValues(alpha: 0.9),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            border: Border.all(
                              color: (isSelected ? ThemeConfig.getClassColor(character.characterClass) : const Color(0xFF1E2C3C))
                                  .withValues(alpha: isSelected ? 0.6 : 0.3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isSelected ? ThemeConfig.getClassColor(character.characterClass) : Colors.black).withValues(alpha: isSelected ? 0.15 : 0),
                                blurRadius: 12,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              // 内部扫描线 (选中时显示)
                              if (isSelected)
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.1,
                                    child: CyberScanline(color: ThemeConfig.getClassColor(character.characterClass)),
                                  ),
                                ),
                              // 角色内容
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isSelected ? ThemeConfig.getClassColor(character.characterClass).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.24),
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(8),
                                              bottomLeft: Radius.circular(8),
                                            ),
                                            border: Border.all(
                                              color: (isSelected ? ThemeConfig.getClassColor(character.characterClass) : Colors.white12),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            ThemeConfig.getClassIcon(character.characterClass),
                                            color: isSelected ? ThemeConfig.getClassColor(character.characterClass) : const Color(0xFF8FA3C0),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          character.name,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : const Color(0xFFE1E9FF),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            letterSpacing: 2,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "初始生命",
                                                  style: TextStyle(
                                                    color: isSelected ? ThemeConfig.getClassColor(character.characterClass).withValues(alpha: 0.5) : Colors.white10,
                                                    fontSize: 7,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                                Text(
                                                  '${character.maxHp}',
                                                  style: TextStyle(
                                                    color: isSelected ? ThemeConfig.getClassColor(character.characterClass) : const Color(0xFF8FA3C0),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "初始信用",
                                                  style: TextStyle(
                                                    color: isSelected ? const Color(0xFFFFD700).withValues(alpha: 0.5) : Colors.white10,
                                                    fontSize: 7,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                                Text(
                                                  '${character.initialGold}',
                                                  style: TextStyle(
                                                    color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF8FA3C0),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "初始牌组数",
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.white10,
                                                    fontSize: 7,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                                Text(
                                                  '${character.startingDeck.length}',
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.blueAccent : const Color(0xFF8FA3C0),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      character.description,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white70 : Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (isSelected && character.passives.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: ThemeConfig.getClassColor(character.characterClass).withValues(alpha: 0.05),
                                          border: Border(left: BorderSide(color: ThemeConfig.getClassColor(character.characterClass), width: 2)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: character.passives.map((p) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              p,
                                              style: TextStyle(
                                                color: ThemeConfig.getClassColor(character.characterClass).withValues(alpha: 0.9),
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          )).toList(),
                                        ),
                                      ),
                                    ],
                                    if (isSelected) ...[
                                      const SizedBox(height: 12),
                                      AnimatedSize(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeOut,
                                        alignment: Alignment.topCenter,
                                        child: _radarExpanded
                                            ? Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: ThemeConfig.getClassColor(character.characterClass).withValues(alpha: 0.04),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: ThemeConfig.getClassColor(character.characterClass).withValues(alpha: 0.3)),
                                                ),
                                                child: SizedBox(
                                                  height: 180,
                                                  child: CyberRadarChart(
                                                    color: ThemeConfig.getClassColor(character.characterClass),
                                                    data: _buildRadarData(character),
                                                    labels: const ['增益', '抽牌', '节奏', '生存', '牌组'],
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (_animatingCharacterId == character.id)
                                Builder(
                                  builder: (context) {
                                    final controller = _animationControllers[character.id];
                                    if (controller == null) return const SizedBox.shrink();
                                    return Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: controller,
                                        builder: (context, _) {
                                          return CustomPaint(
                                            painter: CyberHoloGridPainter(
                                              progress: controller.value,
                                              direction: CyberHoloDirection.horizontal,
                                            ),
                                            child: const SizedBox.expand(),
                                          );
                                        },
                                      ),
                                    );
                                  }
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 关键区域：开始战斗（从第1层随机抽取，不再直接进入地图）
              Container(
                padding: const EdgeInsets.all(16),
                child: CyberButton(
                  heroTag: 'main_action_button',
                  width: double.infinity,
                  label: '同步数据并开始渗透',
                  onPressed: selectedCharacterId != null
                            ? () {
                                 // 关键区域：重置游戏数据，开启新一局
                                 GameProgress.startRun();
                                 GameState.reset();
                                 GameStatistics.reset();
 
                                 // 保存选择的角色ID到全局状态
                                 GameState.selectedCharacterId = selectedCharacterId!;
                                // 更新玩家HP
                                final character = characterDatabase[selectedCharacterId!]!;
                                GameState.playerMaxHp = character.maxHp;
                                GameState.playerHp = character.maxHp;
                                GameState.playerGold = character.initialGold;
                                // 初始化持久化牌组
                                GameState.drawPile = List.from(character.startingDeck);
                                Navigator.push(
                                  context,
                                  createHoloRoute(
                                    const BrainChipSelectionScreen(),
                                  ),
                                );
                              }
                            : null,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
