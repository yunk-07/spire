import 'package:flutter/material.dart';
import 'character_data.dart';
import 'level_data.dart';
import 'main.dart';
import 'game_state.dart';

class _HoloGridPainter extends CustomPainter {
  final double progress;

  _HoloGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.05) {
      return;
    }
    final p = progress.clamp(0.0, 1.0);

    double regionLeft;
    double regionRight;
    if (p < 0.7) {
      final appear = p / 0.7;
      regionLeft = 0;
      regionRight = size.width * appear;
    } else {
      final disappear = (p - 0.7) / 0.3;
      regionLeft = size.width * disappear;
      regionRight = size.width;
    }

    if (regionRight <= regionLeft) {
      return;
    }

    final gridColor = const Color(0x336CE4FF);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    const cell = 16.0;
    for (double x = regionLeft; x <= regionRight; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(regionLeft, y), Offset(regionRight, y), gridPaint);
    }

    const bandWidth = 24.0;
    final bandLeft = (regionRight - bandWidth).clamp(regionLeft, regionRight);
    final bandRight = regionRight;
    if (bandRight <= bandLeft) {
      return;
    }
    final bandRect = Rect.fromLTRB(bandLeft, 0, bandRight, size.height);
    final bandPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0x006CE4FF), Color(0x446CE4FF)],
      ).createShader(bandRect);
    canvas.drawRect(bandRect, bandPaint);
  }

  @override
  bool shouldRepaint(covariant _HoloGridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 开始页面 - 欢迎界面
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 关键区域：背景渐变美化
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF05060A), Color(0xFF0C1018)],
                ),
              ),
            ),
          ),
          Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 游戏标题
            const Text(
              'SPIRE',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6CE4FF),
                letterSpacing: 8.0,
              ),
            ),
            const SizedBox(height: 20),
            
            // 游戏副标题
            const Text(
              'NEURAL ASCENT PROTOCOL',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8FA3C0),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 60),
            
            // 开始游戏按钮
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                backgroundColor: const Color(0xFF101722),
                foregroundColor: const Color(0xFF6CE4FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: const BorderSide(color: Color(0xFF2A4158)),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  createHoloRoute(const CharacterSelectScreen()),
                );
              },
              child: const Text('启动协议', style: TextStyle(letterSpacing: 4)),
            ),
            const SizedBox(height: 20),
            
            // 游戏说明
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: const Text(
                '选择接入单元，上传记忆与战术模块，执行高塔渗透任务。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5D708A),
                ),
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

class _CharacterSelectScreenState extends State<CharacterSelectScreen> with TickerProviderStateMixin {
  String? selectedCharacterId;
  String? _animatingCharacterId;
  final Map<String, AnimationController> _animationControllers = {};

  @override
  void dispose() {
    _animationControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _startAnimation(String characterId) {
    // 停止其他卡片的动画
    for (var id in _animationControllers.keys) {
      if (id != characterId) {
        _animationControllers[id]?.stop();
        _animationControllers[id]?.dispose();
      }
    }
    _animationControllers.removeWhere((id, _) => id != characterId);
    
    // 创建新的动画控制器
    _animationControllers[characterId] = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationControllers[characterId]!.forward().then((_) {
      _animationControllers[characterId]!.dispose();
      _animationControllers.remove(characterId);
      setState(() {
        _animatingCharacterId = null;
      });
    });
    setState(() {
      _animatingCharacterId = characterId;
    });
  }

  // 获取角色图标颜色
  Color _getCharacterColor(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.ironclad:
        return Colors.redAccent;
      case CharacterClass.silent:
        return Colors.greenAccent;
      case CharacterClass.defect:
        return Colors.blueAccent;
      case CharacterClass.watcher:
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  String _getCharacterLabel(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.ironclad:
        return '铁甲';
      case CharacterClass.silent:
        return '静默';
      case CharacterClass.defect:
        return '故障';
      case CharacterClass.watcher:
        return '观者';
      default:
        return '角色';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '选择角色',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('返回', style: TextStyle(color: Colors.white)),
        ),
      ),
      body: Stack(
        children: [
          // 关键区域：背景渐变美化
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF05060A), Color(0xFF0C1018)],
                ),
              ),
            ),
          ),
          Column(
        children: [
          // 角色选择说明
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              '选择接入单元',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8FA3C0),
              ),
            ),
          ),
          
          // 角色列表
          Expanded(
            child: ListView.builder(
              itemCount: characterDatabase.length,
              itemBuilder: (context, index) {
                final character = characterDatabase.values.elementAt(index);
                final isSelected = selectedCharacterId == character.id;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  clipBehavior: Clip.antiAlias,
                  color: const Color(0xFF0F1824),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(
                      color: (isSelected ? const Color(0xFF6CE4FF) : const Color(0xFF1E2C3C))
                          .withValues(alpha: isSelected ? 0.9 : 0.5),
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  elevation: isSelected ? 10 : 3,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedCharacterId = character.id;
                      });
                      _startAnimation(character.id);
                    },
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 160),
                      scale: isSelected ? 1.03 : 1.0,
                      child: SizedBox(
                      height: 140,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF131C2A).withValues(alpha: isSelected ? 0.6 : 0.25),
                                    const Color(0xFF05060A).withValues(alpha: isSelected ? 0.95 : 0.75),
                                  ],
                                ),
                                boxShadow: isSelected
                                    ? [
                                        const BoxShadow(
                                          color: Color(0xFF6CE4FF),
                                          blurRadius: 12,
                                          spreadRadius: 0.5,
                                          offset: Offset(0, 0),
                                        ),
                                      ]
                                    : [],
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A2332).withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: const Color(0xFF2A4158)),
                                    ),
                                    child: Text(
                                      _getCharacterLabel(character.characterClass),
                                      style: const TextStyle(
                                        color: Color(0xFF6CE4FF),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          character.name,
                                          style: const TextStyle(
                                            color: Color(0xFFE1E9FF),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'HP ${character.maxHp}  ·  DECK ${character.startingDeck.length}',
                                          style: const TextStyle(color: Color(0xFF8FA3C0), fontSize: 11),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          character.description,
                                          style: const TextStyle(color: Color(0xFF5D708A), fontSize: 11),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_animatingCharacterId == character.id && _animationControllers.containsKey(character.id))
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _animationControllers[character.id]!,
                                builder: (context, _) {
                                  final t = _animationControllers[character.id]!.value;
                                  return CustomPaint(
                                    painter: _HoloGridPainter(progress: t),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
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
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    backgroundColor: const Color(0xFF101722),
                    foregroundColor: const Color(0xFF6CE4FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                      side: const BorderSide(color: Color(0xFF2A4158)),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF6CE4FF).withValues(alpha: 0.5),
                  ),
              onPressed: selectedCharacterId != null
                      ? () {
                          GameProgress.startRun();
                          final info = GameProgress.startFirstBattle();
                          // 保存选择的角色ID到全局状态
                          GameState.selectedCharacterId = selectedCharacterId!;
                          // 更新玩家HP
                          final character = characterDatabase[selectedCharacterId!]!;
                          GameState.playerMaxHp = character.maxHp;
                          GameState.playerHp = character.maxHp;
                          Navigator.push(
                            context,
                            createHoloRoute(
                              BattlePage(
                                monsterIds: info.monsterIds,
                                levelId: info.id,
                              ),
                            ),
                          );
                        }
                      : null,
              child: const Text('载入实例', style: TextStyle(letterSpacing: 4)),
            ),
          ),
        ],
          ),
        ],
      ),
    );
  }
}
