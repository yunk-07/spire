import 'dart:math';
import 'package:flutter/material.dart';
import 'card_data.dart';
import 'start_screen.dart';
import 'monster_data.dart';
import 'map_screen.dart';
import 'level_data.dart';
import 'game_state.dart';
import 'character_data.dart';

// ============================================================================
// 文件说明 / 主要函数说明及键的作用
// ============================================================================
//
// 【核心状态键说明】
// 1. _cardKeys (Map<int, GlobalKey>) - 卡牌组件的状态键映射
//    - 作用：存储每个卡牌widget的GlobalKey，用于后续动画控制
//    - 使用方式：通过索引访问对应卡牌的key，如 _cardKeys[index]
//    - 重要性：这是实现卡牌拖动动画、缩放效果和状态追踪的关键
//    - 示例：拖动时使用 childWhenDragging 配合 key 实现淡出缩放动画
//
// 2. _cardAnimationControllers (Map<String, AnimationController>)
//    - 作用：管理每张卡牌的扫描动画控制器
//    - 键：卡牌ID (card.id)
//    - 功能：控制扫描进度、卡牌淡入淡出效果
//    - 生命周期：摸牌时创建，动画结束后自动清理
//
// 3. _dealingCards (Set<String>) - 正在发牌动画中的卡牌ID集合
// 4. _discardingCards (Set<String>) - 正在弃牌动画中的卡牌ID集合
//
// 【核心函数说明】
//
// 1. _handArea() - 手牌区域主容器
//    - 根据当前游戏阶段(gamePhase)显示不同视图
//    - 玩家回合(PlayerTurn)：显示扇形手牌视图(_fanHandView)
//    - 弃牌阶段(DiscardPhase)：显示横向选择界面(_discardPhaseView)
//    - 怪物回合(MonsterTurn)：显示扇形手牌视图
//    - 游戏结束(GameOver)：显示空状态
//
// 2. _fanHandView() - 扇形手牌视图（玩家回合主界面）
//    - 功能：将手牌排列成扇形布局，支持动态缩放
//    - 布局算法：
//      * 根据可用宽度计算每个卡牌槽位(slot)
//      * 自动缩放(scale)确保所有卡牌都能显示
//      * 计算旋转角度(maxRot)实现扇形效果
//    - 卡牌交互：支持拖动功能（用于打出手牌）
//    - 动画效果：每张卡牌有淡入缩放动画(TweenAnimationBuilder)
//
// 3. _discardPhaseView() - 弃牌阶段选择界面
//    - 功能：横向排列卡牌，让玩家选择保留哪张
//    - 布局特点：使用ListView实现横向滚动
//    - 缩放逻辑：与扇形视图保持一致的缩放算法
//    - 交互：点击卡牌调用selectCardToKeep()选择保留
//
// 4. _discardPhaseCardView() - 弃牌阶段单张卡牌视图
//    - 参数：
//      * index: 卡牌在手中的索引位置
//      * card: 卡牌数据对象(CardData)
//    - 功能：显示可点击的卡牌，支持点击选择保留
//    - 隐藏处理：正在动画中的卡牌显示为 SizedBox.shrink()
//
// 5. _cardView() - 通用卡牌视图容器（拖动功能）
//    - 功能：包装卡牌widget，添加拖动(Draggable)支持
//    - 核心组件：Draggable<CardData>
//    - 拖动优化：
//      * feedback: 拖动时显示的卡片样式（放大+旋转）
//      * childWhenDragging: 原始位置的卡片动画（淡出+缩小）
//    - 扫描动画：集成卡牌扫描效果（见_scanAnimationStack）
//
// 6. _cardWidget() - 卡牌渲染组件
//    - 功能：根据卡牌类型绘制卡片外观
//    - 参数：
//      * card: 卡牌数据
//      * dragging: 是否正在拖动（改变阴影效果）
//      * showCompleteAnimation: 显示完成动画（发光效果）
//    - 样式：根据cost显示颜色边框，卡面显示名称和描述
//
// 7. selectCardToKeep() - 弃牌阶段选择逻辑
//    - 参数：保留的卡牌ID (cardId)
//    - 处理流程：
//      1. 收集所有要弃掉的卡牌ID到discardIds
//      2. 清空手牌(hand.clear())
//      3. 只添加选中的卡牌(hand.add(cardId))
//      4. 播放弃牌动画并移除其他卡牌
//      5. 进入怪物回合
//
// 8. 卡牌扫描动画流程（摸牌/弃牌阶段）
//    - 阶段1：扫描网格显示
//    - 阶段2：扫描线从上往下移动
//    - 阶段3：扫描进度>80%时卡牌内容淡入
//    - 阶段4：扫描完成，卡牌完全显示
// ============================================================================

class GridPainter extends CustomPainter {
  final Color color;

  GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 1;

    // 绘制水平网格线
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 绘制垂直网格线
    for (double x = 0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// 游戏阶段枚举
enum GamePhase {
  playerTurn, // 玩家回合
  discardPhase, // 弃牌阶段
  monsterTurn, // 怪物回合
  gameOver, // 游戏结束
}

enum MonsterIntent { attack, defend, heal }

void main() {
  runApp(const MyApp());
}

/// =====================
/// 实体
/// =====================

class Entity {
  final String name;
  int hp;
  final int maxHp;
  int block = 0;
  final GlobalKey key = GlobalKey();
  String? id;
  int baseDamage = 8;
  MonsterIntent? intent;
  int intentValue = 0;

  Entity(this.name, this.hp, {int? maxHp}) : maxHp = maxHp ?? hp;
}

/// =====================
/// 伤害弹字
/// =====================

class DamagePopup {
  final int value;
  final Offset pos;
  DamagePopup(this.value, this.pos);
}

/// 关键区域：攻击特效
class AttackEffect {
  final Entity attacker;
  final Offset start;
  final Offset end;
  AttackEffect(this.attacker, this.start, this.end);
}

class CardMotion {
  final String cardId;
  final Offset start;
  final Offset end;
  CardMotion(this.cardId, this.start, this.end);
}

/// 关键区域：护盾受击弹字
class BlockPopup {
  final int value;
  final Offset pos;
  BlockPopup(this.value, this.pos);
}

/// 关键区域：护盾破碎特效
class ShieldBreakEffect {
  final Offset center;
  ShieldBreakEffect(this.center);
}

/// 关键区域：护盾获得弹字
class BlockGainPopup {
  final int value;
  final Offset pos;
  BlockGainPopup(this.value, this.pos);
}

/// 关键区域：治疗恢复弹字
class HealPopup {
  final int value;
  final Offset pos;
  HealPopup(this.value, this.pos);
}

class AnimationService extends ChangeNotifier {
  final List<DamagePopup> popups = [];
  final List<AttackEffect> attacks = [];
  final Set<Entity> charging = {};
  final List<CardMotion> motions = [];
  final List<BlockPopup> blockPopups = [];
  final List<ShieldBreakEffect> shieldBreaks = [];
  final List<BlockGainPopup> blockGains = [];
  final List<HealPopup> healPopups = [];

  bool isCharging(Entity e) => charging.contains(e);

  void showDamage(Entity target, int value) {
    final ctx = target.key.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(const Offset(50, 10));

    final p = DamagePopup(value, pos);
    popups.add(p);
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 800), () {
      popups.remove(p);
      notifyListeners();
    });
  }

  // 关键区域：播放攻击轨迹
  void playAttack(Entity from, Entity to) {
    final fctx = from.key.currentContext;
    final tctx = to.key.currentContext;
    if (fctx == null || tctx == null) return;

    final fbox = fctx.findRenderObject() as RenderBox;
    final tbox = tctx.findRenderObject() as RenderBox;
    final fpos = fbox.localToGlobal(const Offset(50, 40));
    final tpos = tbox.localToGlobal(const Offset(50, 40));

    charging.add(from);
    final eff = AttackEffect(from, fpos, tpos);
    attacks.add(eff);
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 900), () {
      attacks.remove(eff);
      charging.remove(from);
      notifyListeners();
    });
  }

  void playCardMotion(String cardId, Offset start, Offset end) {
    final m = CardMotion(cardId, start, end);
    motions.add(m);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500), () {
      motions.remove(m);
      notifyListeners();
    });
  }

  void showBlockDamage(Entity target, int value) {
    final ctx = target.key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(const Offset(60, 120));
    final b = BlockPopup(value, pos);
    blockPopups.add(b);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 800), () {
      blockPopups.remove(b);
      notifyListeners();
    });
  }

  void playShieldBreak(Entity target) {
    final ctx = target.key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final center = box.localToGlobal(const Offset(60, 80));
    final s = ShieldBreakEffect(center);
    shieldBreaks.add(s);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 600), () {
      shieldBreaks.remove(s);
      notifyListeners();
    });
  }

  void showBlockGain(Entity target, int value) {
    final ctx = target.key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(const Offset(60, 100));
    final b = BlockGainPopup(value, pos);
    blockGains.add(b);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 800), () {
      blockGains.remove(b);
      notifyListeners();
    });
  }

  void showHeal(Entity target, int value) {
    final ctx = target.key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(const Offset(50, 10));
    final h = HealPopup(value, pos);
    healPopups.add(h);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 800), () {
      healPopups.remove(h);
      notifyListeners();
    });
  }
}

/// =====================
/// App
/// =====================

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _darkTheme(),
      home: const StartScreen(),
    );
  }
}

/// 关键区域：全局主题
ThemeData _darkTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6CE4FF),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF05060A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFFE1E9FF),
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      iconTheme: IconThemeData(color: Color(0xFF8FA3C0)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF101722),
        foregroundColor: const Color(0xFF6CE4FF),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF0F1824),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF05060A),
      titleTextStyle: const TextStyle(
        color: Color(0xFFE1E9FF),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      contentTextStyle: const TextStyle(color: Color(0xFF8FA3C0), fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
  );
}

Route<T> createHoloRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 1200),
    reverseTransitionDuration: const Duration(milliseconds: 800),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return _HoloGridOverlay(animation: curved, child: child);
    },
  );
}

class _HoloGridOverlay extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _HoloGridOverlay({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final v = t.clamp(0.0, 1.0);
        return Stack(
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: v == 0 ? 0.001 : v,
                child: child,
              ),
            ),
            if (t > 0 && t < 1)
              IgnorePointer(
                child: CustomPaint(
                  painter: _HoloGridPainter(progress: t),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HoloGridPainter extends CustomPainter {
  final double progress;

  _HoloGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.05) {
      return;
    }
    final p = progress.clamp(0.0, 1.0);

    double regionTop;
    double regionBottom;
    if (p < 0.7) {
      final appear = p / 0.7;
      regionTop = 0;
      regionBottom = size.height * appear;
    } else {
      final disappear = (p - 0.7) / 0.3;
      regionTop = size.height * disappear;
      regionBottom = size.height;
    }

    if (regionBottom <= regionTop) {
      return;
    }

    final gridColor = const Color(0x336CE4FF);
    final gridPaint =
        Paint()
          ..color = gridColor
          ..strokeWidth = 1;

    const cell = 16.0;
    for (double y = regionTop; y <= regionBottom; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, regionTop), Offset(x, regionBottom), gridPaint);
    }

    const bandHeight = 24.0;
    final bandTop = (regionBottom - bandHeight).clamp(regionTop, regionBottom);
    final bandBottom = regionBottom;
    if (bandBottom <= bandTop) {
      return;
    }
    final bandRect = Rect.fromLTRB(0, bandTop, size.width, bandBottom);
    final bandPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x006CE4FF), Color(0x446CE4FF)],
          ).createShader(bandRect);
    canvas.drawRect(bandRect, bandPaint);
  }

  @override
  bool shouldRepaint(covariant _HoloGridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// =====================
/// 战斗页面
/// =====================

class BattlePage extends StatefulWidget {
  /// 可选：来自地图/关卡的怪物ID列表
  final List<String>? monsterIds;

  /// 关卡ID（用于记录进度）
  final String? levelId;
  const BattlePage({super.key, this.monsterIds, this.levelId});
  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> with TickerProviderStateMixin {
  final anim = AnimationService();
  final GlobalKey _drawPileKey = GlobalKey();
  final GlobalKey _discardPileKey = GlobalKey();
  final Map<int, GlobalKey> _cardKeys = {};
  final Set<String> _dealingCards = {};
  final Set<String> _discardingCards = {};
  final Map<String, AnimationController> _cardAnimationControllers = {};

  final player = Entity("玩家", GameState.playerHp, maxHp: GameState.playerMaxHp);
  late List<Entity> monsters;
  late CharacterData characterData; // 当前角色数据

  // 游戏状态提示
  String? _statusTip;
  Color? _statusTipColor;

  int energy = 3;

  // 回合制游戏状态
  GamePhase gamePhase = GamePhase.playerTurn; // 当前游戏阶段
  int turnCount = 1; // 回合计数
  bool isDiscardPhase = false; // 是否处于弃牌阶段
  bool hasDrawnCards = false; // 当前回合是否已抽牌
  bool isVictory = false; // 胜负标识
  bool _victoryRecorded = false; // 胜利记录一次

  @override
  void initState() {
    super.initState();
    // 关键区域：根据地图节点构建怪物
    monsters = _buildMonstersFromIds(widget.monsterIds);
    // 设置DSL效果执行器
    CardEffect.setExecutor(_executeCardEffect);
    // 获取当前角色数据
    characterData = characterDatabase[GameState.selectedCharacterId]!;
    // 初始化抽牌堆
    drawPile.clear();
    drawPile.addAll(characterData.startingDeck);
    drawPile.shuffle();
    // 游戏开始时自动进入玩家回合
    startPlayerTurn();
  }

  @override
  void dispose() {
    // 释放所有动画控制器
    for (final controller in _cardAnimationControllers.values) {
      controller.dispose();
    }
    _cardAnimationControllers.clear();
    super.dispose();
  }

  // 根据怪物ID构建怪物实体
  List<Entity> _buildMonstersFromIds(List<String>? ids) {
    if (ids == null || ids.isEmpty) {
      final s = monsterDatabase['slime'];
      final g = monsterDatabase['goblin'];
      final k = monsterDatabase['skeleton'];
      final ms = <Entity>[];
      if (s != null) {
        final e = Entity(s.name, s.maxHp);
        e.id = s.id;
        e.baseDamage = s.baseDamage;
        ms.add(e);
      }
      if (g != null) {
        final e = Entity(g.name, g.maxHp);
        e.id = g.id;
        e.baseDamage = g.baseDamage;
        ms.add(e);
      }
      if (k != null) {
        final e = Entity(k.name, k.maxHp);
        e.id = k.id;
        e.baseDamage = k.baseDamage;
        ms.add(e);
      }
      return ms;
    }
    return ids.map((id) {
      final data = monsterDatabase[id];
      if (data != null) {
        final e = Entity(data.name, data.maxHp);
        e.id = data.id;
        e.baseDamage = data.baseDamage;
        return e;
      }
      return Entity(id, 30);
    }).toList();
  }

  /// DSL效果执行器实现
  void _executeCardEffect(
    String effect,
    CardData card,
    dynamic target,
    dynamic battle,
  ) {
    final parts = effect.split(' ');
    if (parts.isEmpty) return;

    final command = parts[0];

    switch (command) {
      case 'damage':
        if (target != null && parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? card.value;
          _applyDamage(target as Entity, value);
        }
        break;

      case 'block':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? card.value;
          player.block += value;
          anim.showBlockGain(player, value);
        }
        break;

      case 'draw':
        if (parts.length > 1) {
          final count = int.tryParse(parts[1]) ?? 1;
          drawCount = count;
          drawCards();
        }
        break;

      case 'energy':
        if (parts.length > 1) {
          final value = int.tryParse(parts[1]) ?? 1;
          energy += value;
        }
        break;

      case 'vulnerable':
        if (target != null && parts.length > 1) {
          // 脆弱效果：目标受到额外伤害
          final turns = int.tryParse(parts[1]) ?? 1;
          // 这里可以添加状态效果系统
          // 暂时忽略turns参数，保持代码结构
        }
        break;
    }
  }

  // 当前高亮的可攻击目标
  Entity? highlightedTarget;

  /// 手牌（存 card id）
  final List<String> hand = ["strike_1", "strike_2", "block_1"];

  /// 抽牌堆
  final List<String> drawPile = [
    "strike_1",
    "strike_2",
    "block_1",
    "bash",
    "energy_boost",
    "defend_plus",
  ];

  /// 弃牌堆
  final List<String> discardPile = [];

  /// 抽牌数量
  int drawCount = 5;

  /// =====================
  /// 使用卡牌
  /// =====================

  void useCard(CardData card, Entity? target) {
    if (energy < card.cost) {
      // 显示能量不足提示
      _showStatusTip("能量不足，无法使用该卡牌", Colors.redAccent);
      return;
    }

    energy -= card.cost;
    final idx = hand.indexOf(card.id);
    final hkey = idx >= 0 ? _cardKeys[idx] : null;
    final hctx = hkey?.currentContext;
    final hbox = hctx?.findRenderObject() as RenderBox?;
    final start = hbox?.localToGlobal(const Offset(36, 48));
    final dctx = _discardPileKey.currentContext;
    final dbox = dctx?.findRenderObject() as RenderBox?;
    final end = dbox?.localToGlobal(const Offset(50, 30));
    if (start != null && end != null) {
      anim.playCardMotion(card.id, start, end);
    }
    hand.remove(card.id);

    // 使用后的卡牌进入弃牌堆
    discardPile.add(card.id);

    // 使用DSL系统处理卡牌效果
    if (card.effect != null) {
      // 关键区域：攻击动画触发
      if (target != null &&
          (card.type == CardType.attack || card.effect!.contains('damage'))) {
        anim.playAttack(player, target);
        // 添加攻击音效
        _playAttackSound();
      }
      CardEffect.execute(card.effect!, card, target, this);
    } else {
      // 如果没有DSL效果，使用默认逻辑
      if (card.type == CardType.attack && target != null) {
        anim.playAttack(player, target);
        _applyDamage(target, card.value);
        // 添加攻击音效
        _playAttackSound();
      }

      if (card.type == CardType.block) {
        player.block += card.value;
        anim.showBlockGain(player, card.value);
        // 添加格挡音效
        _playBlockSound();
      }
    }
    // 增加使用卡牌统计
    GameStatistics.totalCardsUsed++;

    // 重置高亮目标
    highlightedTarget = null;

    // 关键区域：使用卡牌后检查胜负
    checkBattleResult();

    setState(() {});
  }

  // 显示游戏状态提示
  void _showStatusTip(String message, Color color) {
    setState(() {
      _statusTip = message;
      _statusTipColor = color;
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() {
        _statusTip = null;
      });
    });
  }

  // 播放攻击音效
  void _playAttackSound() {
    // 可以在这里添加攻击音效的实现
  }

  // 播放格挡音效
  void _playBlockSound() {
    // 可以在这里添加格挡音效的实现
  }

  void _applyDamage(Entity target, int value) {
    if (value <= 0) return;
    int remaining = value;
    if (target.block > 0) {
      final absorbed = remaining.clamp(0, target.block);
      target.block -= absorbed;
      remaining -= absorbed;
      if (absorbed > 0) {
        anim.showBlockDamage(target, absorbed);
        // 添加格挡音效
        _playBlockSound();
        // 增加格挡伤害统计
        GameStatistics.totalDamageBlocked += absorbed;
      }
      if (target.block == 0 && absorbed > 0) {
        anim.playShieldBreak(target);
      }
    }
    if (remaining > 0) {
      target.hp = max(0, target.hp - remaining);
      anim.showDamage(target, remaining);
      // 添加受击音效
      _playHitSound();
      // 增加造成伤害统计
      GameStatistics.totalDamageDealt += remaining;
    }
    if (identical(target, player)) {
      GameState.playerHp = target.hp;
    }
  }

  // 播放受击音效
  void _playHitSound() {
    // 可以在这里添加受击音效的实现
  }

  /// =====================
  /// 抽牌
  /// =====================

  void drawCards() {
    if (drawPile.isEmpty) {
      // 如果抽牌堆为空，将弃牌堆洗入抽牌堆
      drawPile.addAll(discardPile);
      discardPile.clear();
      // 洗牌
      drawPile.shuffle();
    }

    final cardsToDraw = drawCount.clamp(0, drawPile.length);
    final newCards = <String>[];
    for (int i = 0; i < cardsToDraw; i++) {
      final id = drawPile.removeAt(0);
      hand.add(id);
      newCards.add(id);
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final drawCtx = _drawPileKey.currentContext;
      final drawBox = drawCtx?.findRenderObject() as RenderBox?;
      final start = drawBox?.localToGlobal(const Offset(50, 30));
      // 新增卡的索引位于 hand 尾部
      final startIndex = hand.length - newCards.length;
      for (int i = 0; i < newCards.length; i++) {
        final idx = startIndex + i;
        final key = _cardKeys[idx];
        final ctx = key?.currentContext;
        final box = ctx?.findRenderObject() as RenderBox?;
        final end = box?.localToGlobal(const Offset(36, 48));
        if (start != null && end != null) {
          // 移除原有的发牌动画，改为扫描带显现
        }
      }
    });
  }

  /// =====================
  /// 结束回合
  /// =====================

  void endTurn() {
    final ids = List<String>.from(hand);
    for (int idx = 0; idx < ids.length; idx++) {
      final id = ids[idx];
      final key = _cardKeys[idx];
      final ctx = key?.currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      final start = box?.localToGlobal(const Offset(36, 48));
      final dctx = _discardPileKey.currentContext;
      final dbox = dctx?.findRenderObject() as RenderBox?;
      final end = dbox?.localToGlobal(const Offset(50, 30));
      if (start != null && end != null) {
        _discardingCards.add(id);
        // 创建动画控制器
        _cardAnimationControllers[id] = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        );
        // 启动动画
        _cardAnimationControllers[id]?.forward();
        setState(() {});
        // 移除原有的弃牌动画，改为扫描带消失
        Future.delayed(const Duration(milliseconds: 820), () {
          _discardingCards.remove(id);
          hand.remove(id);
          discardPile.add(id);
          // 释放动画控制器
          _cardAnimationControllers[id]?.dispose();
          _cardAnimationControllers.remove(id);
          setState(() {});
        });
      }
    }
    Future.delayed(const Duration(milliseconds: 860), () {
      energy = 3;
      drawCards();
      // 增加回合数统计
      GameStatistics.totalTurns++;
      setState(() {});
    });
  }

  /// =====================
  /// 回合制游戏规则系统
  /// =====================

  /// 开始玩家回合
  void startPlayerTurn() {
    gamePhase = GamePhase.playerTurn;
    isDiscardPhase = false;
    hasDrawnCards = false;
    player.block = 0; // 回合开始重置护盾

    // 每回合开始时重置能量为固定值
    energy = 3;

    // 玩家回合开始时自动抽牌：随机抽取随机张牌
    _randomDrawCards();
    hasDrawnCards = true;
    _rollMonsterIntents();

    setState(() {});
  }

  /// 随机抽牌逻辑：随机抽取随机张牌
  void _randomDrawCards() {
    if (drawPile.isEmpty) {
      drawPile.addAll(discardPile);
      discardPile.clear();
      drawPile.shuffle();
    }

    final random = Random();
    final cardsToDraw =
        random.nextInt(
          characterData.maxDrawPerTurn - characterData.minDrawPerTurn + 1,
        ) +
        characterData.minDrawPerTurn;
    final actualDrawCount = cardsToDraw.clamp(1, drawPile.length);

    final newCards = <String>[];
    for (int i = 0; i < actualDrawCount; i++) {
      final id = drawPile.removeAt(0);
      hand.add(id);
      newCards.add(id);
    }

    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final drawCtx = _drawPileKey.currentContext;
      final drawBox = drawCtx?.findRenderObject() as RenderBox?;
      final start = drawBox?.localToGlobal(const Offset(50, 30));
      final startIndex = hand.length - newCards.length;
      for (int i = 0; i < newCards.length; i++) {
        final idx = startIndex + i;
        final key = _cardKeys[idx];
        final ctx = key?.currentContext;
        final box = ctx?.findRenderObject() as RenderBox?;
        final end = box?.localToGlobal(const Offset(36, 48));
        if (start != null && end != null) {
          final cid = hand[idx];
          _dealingCards.add(cid);
          // 创建动画控制器
          _cardAnimationControllers[cid] = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          );
          // 启动动画
          _cardAnimationControllers[cid]?.forward();
          setState(() {});
          // 移除原有的发牌动画，改为扫描带显现
          Future.delayed(const Duration(milliseconds: 820), () {
            _dealingCards.remove(cid);
            // 释放动画控制器
            _cardAnimationControllers[cid]?.dispose();
            _cardAnimationControllers.remove(cid);
            setState(() {});
          });
        }
      }
    });
  }

  /// 进入弃牌阶段
  void startDiscardPhase() {
    gamePhase = GamePhase.discardPhase;
    isDiscardPhase = true;
    if (hand.isEmpty) {
      completeDiscardPhase();
      return;
    }
    setState(() {});
  }

  /// 开始怪物回合
  void startMonsterTurn() {
    gamePhase = GamePhase.monsterTurn;
    isDiscardPhase = false;

    // 怪物行动逻辑
    _monsterActions();

    // 怪物回合结束后进入下一回合
    turnCount++;
    startPlayerTurn();
  }

  /// 怪物行动逻辑
  void _monsterActions() {
    print("怪物回合开始");

    for (final monster in monsters) {
      if (monster.hp > 0) {
        print("${monster.name}开始行动");
        switch (monster.intent) {
          case MonsterIntent.attack:
            _monsterAttackPlayer(monster, predicted: monster.intentValue);
            break;
          case MonsterIntent.defend:
            _monsterDefend(monster, value: monster.intentValue);
            break;
          case MonsterIntent.heal:
            _monsterHeal(monster, amount: monster.intentValue);
            break;
          default:
            _monsterAttackPlayer(monster);
            break;
        }
        monster.intent = null;
        monster.intentValue = 0;
      }
    }

    print("怪物回合结束");
    // 关键区域：怪物回合结束后检查胜负
    checkBattleResult();
    setState(() {});
  }

  /// 怪物攻击玩家
  void _monsterAttackPlayer(Entity monster, {int? predicted}) {
    final random = Random();
    int totalDamage =
        predicted ??
        (monster.baseDamage + (turnCount ~/ 3) + random.nextInt(3));
    // 关键区域：怪物攻击动画
    anim.playAttack(monster, player);

    // 延迟执行伤害，等待攻击动画完成后再处理伤害和判定
    Future.delayed(const Duration(milliseconds: 500), () {
      _applyDamage(player, totalDamage);
      // 关键区域：玩家生命值检查
      checkBattleResult();
    });

    print("${monster.name}攻击玩家，造成$totalDamage点伤害");
  }

  /// 怪物恢复生命值
  void _monsterHeal(Entity monster, {int? amount}) {
    final random = Random();
    final healAmount = amount ?? (random.nextInt(5) + 3);
    monster.hp = (monster.hp + healAmount).clamp(0, monster.maxHp);

    anim.showHeal(monster, healAmount);

    print("${monster.name}恢复了$healAmount点生命值");
  }

  void _monsterDefend(Entity monster, {int? value}) {
    final random = Random();
    final v = value ?? (3 + (turnCount ~/ 3) + random.nextInt(4));
    monster.block += v;
    print("${monster.name}获得了$v点护盾");
    anim.showBlockGain(monster, v);
  }

  void _rollMonsterIntents() {
    final random = Random();
    for (final m in monsters) {
      if (m.hp <= 0) {
        m.intent = null;
        m.intentValue = 0;
        continue;
      }
      final lowHp = m.hp < m.maxHp * 0.3;
      final p = random.nextDouble();
      if (lowHp && p < 0.4) {
        m.intent = MonsterIntent.heal;
        m.intentValue = random.nextInt(5) + 3;
      } else if (p < 0.25) {
        m.intent = MonsterIntent.defend;
        m.intentValue = 3 + (turnCount ~/ 3) + random.nextInt(4);
      } else {
        m.intent = MonsterIntent.attack;
        m.intentValue = m.baseDamage + (turnCount ~/ 3) + random.nextInt(3);
      }
    }
  }

  /// 检查能量耗尽自动进入弃牌阶段
  void checkEnergyExhaustion() {
    if (energy <= 0 && gamePhase == GamePhase.playerTurn && !isDiscardPhase) {
      startDiscardPhase();
    }
  }

  /// 完成弃牌阶段
  void completeDiscardPhase() {
    if (hand.length > 1) {
      // 如果手牌超过1张，需要玩家手动选择保留哪张
      // 这里暂时自动保留第一张，弃掉其他
      final cardToKeep = hand[0];
      for (int idx = 1; idx < hand.length; idx++) {
        final id = hand[idx];
        final key = _cardKeys[idx];
        final ctx = key?.currentContext;
        final box = ctx?.findRenderObject() as RenderBox?;
        final start = box?.localToGlobal(const Offset(36, 48));
        final dctx = _discardPileKey.currentContext;
        final dbox = dctx?.findRenderObject() as RenderBox?;
        final end = dbox?.localToGlobal(const Offset(50, 30));
        if (start != null && end != null) {
          _discardingCards.add(id);
          // 创建动画控制器
          _cardAnimationControllers[id] = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          );
          // 启动动画
          _cardAnimationControllers[id]?.forward();
          setState(() {});
          // 移除原有的弃牌动画，改为扫描带消失
          Future.delayed(const Duration(milliseconds: 820), () {
            _discardingCards.remove(id);
            // 释放动画控制器
            _cardAnimationControllers[id]?.dispose();
            _cardAnimationControllers.remove(id);
            setState(() {});
          });
        }
      }
      discardPile.addAll(hand.sublist(1));
      hand.clear();
      hand.add(cardToKeep);

      // 显示弃牌信息
      print("弃牌阶段：保留了1张牌，弃掉了${hand.length - 1}张牌");
    } else if (hand.length == 1) {
      // 如果只有1张牌，直接保留
      print("弃牌阶段：保留了1张牌");
    } else {
      // 如果没有手牌，跳过弃牌阶段
      print("弃牌阶段：没有手牌可弃");
    }

    // 弃牌阶段结束后进入怪物回合
    startMonsterTurn();
  }

  // 关键区域：胜负判定
  void checkBattleResult() {
    if (player.hp <= 0 && gamePhase != GamePhase.gameOver) {
      gamePhase = GamePhase.gameOver;
      isVictory = false;
      setState(() {});
      return;
    }
    if (monsters.isNotEmpty &&
        monsters.every((m) => m.hp <= 0) &&
        gamePhase != GamePhase.gameOver) {
      gamePhase = GamePhase.gameOver;
      isVictory = true;
      if (!_victoryRecorded && widget.levelId != null) {
        GameProgress.markDefeated(widget.levelId!);
        _victoryRecorded = true;
      }
      setState(() {});
    }
  }

  /// 手动选择保留的牌（供UI调用）
  void selectCardToKeep(String cardId) {
    if (gamePhase != GamePhase.discardPhase) return;

    // 将选中的牌保留，其他牌弃掉
    final discardIds = <String>[];
    for (final id in hand) {
      if (id != cardId) {
        discardIds.add(id);
      }
    }

    // 对所有要弃掉的卡牌播放动画
    for (final id in discardIds) {
      final idx = hand.indexOf(id);
      if (idx >= 0) {
        final key = _cardKeys[idx];
        final ctx = key?.currentContext;
        final box = ctx?.findRenderObject() as RenderBox?;
        final start = box?.localToGlobal(const Offset(36, 48));
        final dctx = _discardPileKey.currentContext;
        final dbox = dctx?.findRenderObject() as RenderBox?;
        final end = dbox?.localToGlobal(const Offset(50, 30));
        if (start != null && end != null) {
          _discardingCards.add(id);
          // 创建动画控制器
          _cardAnimationControllers[id] = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          );
          // 启动动画
          _cardAnimationControllers[id]?.forward();
          setState(() {});
          // 移除弃牌动画
          Future.delayed(const Duration(milliseconds: 820), () {
            _discardingCards.remove(id);
            discardPile.add(id);
            // 释放动画控制器
            _cardAnimationControllers[id]?.dispose();
            _cardAnimationControllers.remove(id);
            setState(() {});
          });
        }
      }
    }

    // 清空手牌，只保留选中的卡牌
    hand.clear();
    hand.add(cardId);

    // 显示弃牌信息
    print("弃牌阶段：选择了1张牌保留，弃掉了${discardIds.length}张牌");

    // 完成弃牌阶段
    completeDiscardPhase();
  }

  /// =====================
  /// UI
  /// =====================

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return WillPopScope(
      // 关键区域：返回确认并跳转开始页面
      onWillPop: _onWillPopConfirm,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: anim,
          builder:
              (context, _) => Stack(
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
                  // 根据屏幕方向选择不同布局
                  isLandscape ? _landscapeLayout() : _portraitLayout(),
                  // 弃牌阶段：显示卡牌选择覆盖层
                  if (gamePhase == GamePhase.discardPhase && isDiscardPhase)
                    _bottomDiscardOverlay(),
                  // 玩家回合：显示进入弃牌按钮
                  if (gamePhase == GamePhase.playerTurn &&
                      hasDrawnCards &&
                      !isDiscardPhase)
                    _bottomDiscardOverlay(),
                  ...anim.attacks.map(_attackEffect),
                  ...anim.motions.map(_cardMotionWidget),
                  ...anim.blockPopups.map(_blockDamagePopup),
                  ...anim.shieldBreaks.map(_shieldBreakEffect),
                  ...anim.popups.map(_damagePopup),
                  ...anim.blockGains.map(_blockGainPopup),
                  ...anim.healPopups.map(_healPopup),
                  if (gamePhase == GamePhase.gameOver) _resultOverlay(),
                  if (_statusTip != null) _statusTipWidget(),
                ],
              ),
        ),
      ),
    );
  }

  // 竖屏布局：顶部栏 -> 怪物区域 -> 手牌区域 -> 牌堆区域
  Widget _portraitLayout() {
    return Column(
      children: [
        _topBar(), // 顶部状态栏
        _battleField(), // 怪物战斗区域
        Expanded(child: _handArea()), // 手牌区域（占据剩余空间）
        _pileArea(), // 牌堆区域
      ],
    );
  }

  // 横屏布局：左侧怪物区域 -> 中间手牌区域 -> 右侧顶部状态栏和牌堆区域
  Widget _landscapeLayout() {
    return Row(
      children: [
        Expanded(child: _battleField()), // 怪物战斗区域（占据左侧空间）
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _topBar(), // 顶部状态栏
              Expanded(child: _handArea()), // 手牌区域（占据中间空间）
              _pileArea(), // 牌堆区域
            ],
          ),
        ),
      ],
    );
  }

  // 游戏状态提示组件
  Widget _statusTipWidget() {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _statusTipColor ?? Colors.redAccent),
            boxShadow: [
              BoxShadow(
                color:
                    _statusTipColor?.withOpacity(0.5) ??
                    Colors.redAccent.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            _statusTip!,
            style: TextStyle(
              color: _statusTipColor ?? Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 关键区域：顶部HUD（SafeArea避免状态栏遮挡）
  Widget _topBar() {
    return SafeArea(
      top: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF101722).withOpacity(0.95),
              const Color(0xFF101722).withOpacity(0.85),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF2A4158).withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 左侧：HP进度条 + 护盾值
            Row(
              children: [
                Container(
                  width: 180,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF05060A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A4158)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value:
                              player.maxHp == 0 ? 0 : player.hp / player.maxHp,
                          backgroundColor: const Color(0xFF05060A),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6CE4FF),
                          ),
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 14,
                              color: Color(0xFF6CE4FF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${player.hp}/${player.maxHp}",
                              style: const TextStyle(
                                color: Color(0xFFE1E9FF),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05060A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A4158)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield,
                        size: 14,
                        color: Color(0xFF5AD1FF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${player.block}",
                        style: const TextStyle(
                          color: Color(0xFF5AD1FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 右侧：能量小圆点
            Row(
              children: [
                for (int i = 0; i < energy; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.bolt,
                      size: 18,
                      color: const Color(0xFF6CE4FF),
                      shadows: [
                        Shadow(
                          color: const Color(0xFF6CE4FF).withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取游戏阶段对应的颜色

  // 关键区域：底部“进入弃牌”覆盖层（SafeArea避免底部遮挡）
  Widget _bottomDiscardOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: GestureDetector(
              onTap: startDiscardPhase,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF101722),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6CE4FF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFF6CE4FF).withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.delete_sweep,
                    color: Color(0xFF6CE4FF),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 获取游戏阶段对应的文本

  Widget _battleField() {
    return Container(
      height: 240,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _playerTarget(),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        monsters
                            .map((monster) => _monsterWidget(monster))
                            .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerTarget() {
    return DragTarget<CardData>(
      onWillAccept: (card) {
        if (card == null) return false;
        final eff = card.effect ?? "";
        final accept =
            card.type == CardType.block ||
            card.type == CardType.skill ||
            eff.contains('block') ||
            eff.contains('energy');
        return accept;
      },
      onAccept: (card) {
        useCard(card, player);
        // 添加卡牌使用时的粒子效果
        _showCardUseEffect(card, player);
      },
      builder: (context, candidateData, rejectedData) {
        return _playerWidget(player);
      },
    );
  }

  Widget _playerWidget(Entity e) {
    final box = Container(
      key: e.key,
      width: 80,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFF152235),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF2A4158)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 48, color: Colors.white70),
          const SizedBox(height: 8),
        ],
      ),
    );
    return AnimatedOpacity(
      opacity: anim.isCharging(e) ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: box,
    );
  }

  // 关键区域：结果层（胜利/失败）
  Widget _resultOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            builder: (_, t, __) {
              final scale = 0.85 + 0.15 * t;
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (isVictory) _victoryParticles(t),
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 320,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF05060A),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFF2A4158)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 18,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          isVictory
                              ? _victoryTitle(t)
                              : const Text(
                                '游戏结束',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          const SizedBox(height: 16),
                          _gameStatisticsWidget(),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (isVictory) ...[
                                _overlayButton(
                                  Icons.map,
                                  () {
                                    Navigator.push(
                                      context,
                                      createHoloRoute(
                                        const MapScreen(canReturnToGame: true),
                                      ),
                                    );
                                  },
                                  colors: const [
                                    Color(0xFF3AA0FF),
                                    Color(0xFF64E1FF),
                                  ],
                                ),
                                _overlayButton(
                                  Icons.skip_next,
                                  () {
                                    final next = GameProgress.nextRandomLevel();
                                    if (next != null) {
                                      Navigator.pushReplacement(
                                        context,
                                        createHoloRoute(
                                          BattlePage(
                                            monsterIds: next.monsterIds,
                                            levelId: next.id,
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        createHoloRoute(const MapScreen()),
                                      );
                                    }
                                  },
                                  colors: const [
                                    Color(0xFFFFA06A),
                                    Color(0xFFFF6A6A),
                                  ],
                                ),
                              ] else ...[
                                _overlayButton(
                                  Icons.refresh,
                                  () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      createHoloRoute(const StartScreen()),
                                      (route) => false,
                                    );
                                  },
                                  colors: const [
                                    Color(0xFFFF6A6A),
                                    Color(0xFFFFA06A),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // 关键区域：结果页自定义按钮
  Widget _overlayButton(
    IconData icon,
    VoidCallback onTap, {
    List<Color>? colors,
  }) {
    final base = colors?.first ?? const Color(0xFF101722);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFF2A4158)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 24)),
      ),
    );
  }

  // 关键区域：胜利页面标题（动态渐变）
  Widget _victoryTitle(double t) {
    final paint =
        Paint()
          ..shader = const LinearGradient(
            colors: [Colors.amber, Colors.orangeAccent, Colors.redAccent],
            begin: Alignment(-1, 0),
            end: Alignment(1, 0),
          ).createShader(Rect.fromLTWH(20 * t, 0, 300, 60));
    return Text(
      '胜利！',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        foreground: paint,
      ),
    );
  }

  // 游戏统计信息组件
  Widget _gameStatisticsWidget() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF101722),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A4158)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '战斗统计',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '造成伤害:',
                    style: TextStyle(color: Color(0xFF6CE4FF), fontSize: 14),
                  ),
                  Text(
                    '${GameStatistics.totalDamageDealt}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '格挡伤害:',
                    style: TextStyle(color: Color(0xFF6CE4FF), fontSize: 14),
                  ),
                  Text(
                    '${GameStatistics.totalDamageBlocked}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '使用卡牌:',
                    style: TextStyle(color: Color(0xFF6CE4FF), fontSize: 14),
                  ),
                  Text(
                    '${GameStatistics.totalCardsUsed}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '回合数:',
                    style: TextStyle(color: Color(0xFF6CE4FF), fontSize: 14),
                  ),
                  Text(
                    '${GameStatistics.totalTurns}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 关键区域：胜利粒子效果（星光）
  Widget _victoryParticles(double t) {
    final stars = <Alignment>[
      const Alignment(-0.6, -0.7),
      const Alignment(0.7, -0.6),
      const Alignment(-0.8, 0.1),
      const Alignment(0.8, 0.2),
      const Alignment(-0.2, 0.85),
      const Alignment(0.3, 0.75),
    ];
    return Stack(
      children:
          stars
              .map(
                (a) => Align(
                  alignment: a,
                  child: Opacity(
                    opacity: (0.1 + 0.9 * t).clamp(0.0, 1.0) as double,
                    child: Transform.scale(
                      scale: 0.8 + 0.2 * t,
                      child: const Icon(
                        Icons.star,
                        color: Colors.amberAccent,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Future<bool> _onWillPopConfirm() async {
    final res = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('确认返回？'),
            content: const Text('将返回到开始页面并结束当前游戏'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    createHoloRoute(const StartScreen()),
                    (route) => false,
                  );
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
    return Future.value(res ?? false);
  }

  Widget _monsterWidget(Entity monster) {
    return DragTarget<CardData>(
      onWillAccept: (card) {
        if (card?.type == CardType.attack && monster.hp > 0) {
          highlightedTarget = monster;
          setState(() {});
          return true;
        }
        return false;
      },
      onAccept: (card) {
        useCard(card, monster);
        // 添加卡牌使用时的粒子效果
        _showCardUseEffect(card, monster);
      },
      onLeave: (_) {
        highlightedTarget = null;
        setState(() {});
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = highlightedTarget == monster;
        final isBeingDragged = candidateData.isNotEmpty;
        final isDead = monster.hp <= 0;

        final box = AnimatedContainer(
          key: monster.key,
          duration: const Duration(milliseconds: 200),
          width: 120, // 增大怪物卡片尺寸
          height: 140,
          decoration: BoxDecoration(
            color:
                isDead
                    ? Colors.grey.shade500
                    : (isHighlighted
                        ? Colors.red.shade200
                        : (isBeingDragged
                            ? Colors.grey.shade400
                            : Colors.grey.shade300)),
            borderRadius: BorderRadius.circular(8), // 增大圆角
            border:
                isHighlighted
                    ? Border.all(color: const Color(0xFF6CE4FF), width: 2.0)
                    : Border.all(
                      color: Colors.black.withOpacity(0.4),
                      width: 1,
                    ),
            boxShadow:
                isHighlighted
                    ? [
                      const BoxShadow(
                        color: Colors.black,
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child: Icon(Icons.pest_control, size: 48, color: Colors.black54),
          ),
        );
        final statusText =
            !isDead && isHighlighted ? "可攻击" : (isDead ? "死亡" : null);
        String? intentText;
        Color? intentColor;
        switch (monster.intent) {
          case MonsterIntent.attack:
            intentText = "攻击 ${monster.intentValue}";
            intentColor = Colors.redAccent;
            break;
          case MonsterIntent.defend:
            intentText = "防御 ${monster.intentValue}";
            intentColor = Colors.cyanAccent;
            break;
          case MonsterIntent.heal:
            intentText = "治疗 ${monster.intentValue}";
            intentColor = Colors.greenAccent;
            break;
          default:
            intentText = null;
            intentColor = null;
        }

        return AnimatedOpacity(
          opacity: isDead ? 0.4 : (anim.isCharging(monster) ? 0.0 : 1.0),
          duration: const Duration(milliseconds: 100),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              box,
              Positioned(
                top: 10,
                child: Text(
                  monster.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              if (intentText != null)
                Positioned(
                  top: -60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (intentColor ?? const Color(0xFF101722))
                          .withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2A4158)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      intentText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE1E9FF),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: -36,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05060A).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A4158)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        "HP ${monster.hp}",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE1E9FF),
                        ),
                      ),
                      if (monster.block > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          "SHD ${monster.block}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5AD1FF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (statusText != null)
                Positioned(
                  top: -16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDead
                              ? const Color(0xFF252525)
                              : const Color(0xFF101722),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isDead
                                ? const Color(0xFF444444)
                                : const Color(0xFF6CE4FF),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE1E9FF),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _pileArea() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          KeyedSubtree(
            key: _drawPileKey,
            child: _pileWidget(
              Icons.layers,
              drawPile.length,
              Colors.blue.shade200,
            ),
          ),
          const SizedBox(width: 20),
          KeyedSubtree(
            key: _discardPileKey,
            child: _pileWidget(
              Icons.delete,
              discardPile.length,
              Colors.red.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pileWidget(IconData icon, int count, Color color) {
    return Container(
      width: 120,
      height: 70,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.black87,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _handArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                gamePhase == GamePhase.discardPhase
                    ? Icons.delete_sweep
                    : Icons.back_hand,
                size: 18,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                "${hand.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                gamePhase == GamePhase.discardPhase
                    ? _discardPhaseView() // 弃牌阶段特殊界面
                    : _fanHandView(),
          ),
        ],
      ),
    );
  }

  // 关键区域：手牌扇形视图
  Widget _fanHandView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const cardW = 72.0;
        const cardH = 96.0;
        final n = hand.length;
        if (n == 0) {
          return const Center(
            child: Icon(Icons.inbox_outlined, size: 28, color: Colors.white38),
          );
        }

        final margin = 8.0;
        final availableW = max(0.0, w - margin * 2);
        final slot = availableW / n;
        final scale = slot >= cardW ? 1.0 : max(0.6, slot / cardW);
        final cardWS = cardW * scale;
        final cardHS = cardH * scale;
        final baseY = max(0.0, h - cardHS - margin);
        final maxRot = 0.18;

        final children = <Widget>[];
        for (int i = 0; i < n; i++) {
          final t = n == 1 ? 0.5 : i / (n - 1);
          final rot = (t - 0.5) * 2 * maxRot;
          var dx = margin + i * slot + (slot - cardWS) / 2;
          dx = dx.clamp(0.0, w - cardWS);

          final card = cardDatabase[hand[i]]!;
          children.add(
            Positioned(
              left: dx,
              top: baseY,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 200),
                builder:
                    (_, __, ___) => Transform.rotate(
                      angle: rot,
                      child: Transform.scale(
                        scale: scale,
                        child: _cardView(i, card),
                      ),
                    ),
              ),
            ),
          );
        }

        return Stack(children: children);
      },
    );
  }

  /// 弃牌阶段界面：让玩家选择保留哪张牌（使用与扇形视图一致的布局）
  Widget _discardPhaseView() {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              const cardW = 72.0;
              const cardH = 96.0;
              final n = hand.length;
              if (n == 0) {
                return const Center(
                  child: Icon(Icons.inbox_outlined, size: 28, color: Colors.white38),
                );
              }

              final margin = 8.0;
              final availableW = max(0.0, w - margin * 2);
              final slot = availableW / n;
              final scale = slot >= cardW ? 1.0 : max(0.6, slot / cardW);
              final cardWS = cardW * scale;
              final cardHS = cardH * scale;
              final baseY = max(0.0, h - cardHS - margin);
              final maxRot = 0.18;

              final children = <Widget>[];
              for (int i = 0; i < n; i++) {
                final t = n == 1 ? 0.5 : i / (n - 1);
                final rot = (t - 0.5) * 2 * maxRot;
                var dx = margin + i * slot + (slot - cardWS) / 2;
                dx = dx.clamp(0.0, w - cardWS);

                final card = cardDatabase[hand[i]]!;
                children.add(
                  Positioned(
                    left: dx,
                    top: baseY,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 200),
                      builder: (_, __, ___) => GestureDetector(
                        onTap: () => selectCardToKeep(card.id),
                        child: Transform.rotate(
                          angle: rot,
                          child: Transform.scale(
                            scale: scale,
                            child: _cardView(i, card),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Stack(children: children);
            },
          ),
        ),
        // 底部提示文字
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            "点击卡牌保留，其他将弃掉",
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade800.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  /// 弃牌阶段的卡牌视图（可点击选择保留）
  /// @param index - 卡牌在手中的索引位置
  /// @param card - 卡牌数据对象
  Widget _discardPhaseCardView(int index, CardData card) {
    final hidden =
        _dealingCards.contains(card.id) || _discardingCards.contains(card.id);
    return GestureDetector(
      onTap: () => selectCardToKeep(card.id),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: KeyedSubtree(
          key: _cardKeys[index] ??= GlobalKey(),
          child: hidden ? const SizedBox.shrink() : _cardWidget(card),
        ),
      ),
    );
  }

  Widget _cardView(int index, CardData card) {
    return Stack(
      children: [
        Draggable<CardData>(
          data: card,

          // 拖动开始时的回调
          onDragStarted: () {
            // 添加拖动开始的动画效果
            setState(() {
              // 可以在这里添加拖动开始的状态变化
            });
          },

          // 拖动结束时的回调
          onDragEnd: (details) {
            // 添加拖动结束的动画效果
            setState(() {
              // 可以在这里添加拖动结束的状态变化
            });
          },

          /// 🔑 优化点 1：feedback 用 Material 包裹，添加更流畅的动画效果
          feedback: Material(
            color: Colors.transparent,
            elevation: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 88, // 竖屏布局中略微增大卡牌尺寸
              height: 114,
              child: Transform.rotate(
                angle: 0.08, // 轻微旋转增加动态感
                child: _cardWidget(card, dragging: true),
              ),
            ),
          ),

          /// 🔑 优化点 2：childWhenDragging 固定尺寸，添加吸附动画和阴影效果
          childWhenDragging: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 1.0, end: 0.2),
            builder: (context, opacity, child) {
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: 0.85, // 缩小效果更明显
                  child: SizedBox(
                    width: 72,
                    height: 96,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _cardWidget(card, showCompleteAnimation: true),
                    ),
                  ),
                ),
              );
            },
          ),

          child: KeyedSubtree(
            key: _cardKeys[index] ??= GlobalKey(),
            child: SizedBox(
              width: 72,
              height: 96,
              // 🔧 修复：扫描动画期间隐藏正常卡牌，扫描完成后再显示
              child:
                  _dealingCards.contains(card.id) &&
                          _cardAnimationControllers.containsKey(card.id) &&
                          _cardAnimationControllers[card.id]!.value < 1.0
                      ? const SizedBox.shrink() // 扫描未完成时不显示
                      : _cardWidget(card),
            ),
          ),
        ),
        // 摸牌扫描带动画
        if (_dealingCards.contains(card.id) &&
            _cardAnimationControllers.containsKey(card.id))
          AnimatedBuilder(
            animation: _cardAnimationControllers[card.id]!,
            builder: (context, child) {
              Color getScanColor() {
                switch (card.level) {
                  case 1:
                    return Colors.green.shade400;
                  case 2:
                    return Colors.blue.shade400;
                  case 3:
                    return Colors.purple.shade400;
                  case 4:
                    return Colors.orange.shade400;
                  case 5:
                    return Colors.red.shade400;
                  default:
                    return Colors.grey.shade400;
                }
              }

              final scanColor = getScanColor();
              final progress = _cardAnimationControllers[card.id]!.value;
              
              // 特写动画：扫描完成后放大弹跳
              final completionProgress = (progress - 0.8).clamp(0.0, 1.0) * 5;
              final zoomEffect = completionProgress >= 1.0
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.15),
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      builder: (context, zoom, child) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.15, end: 1.0),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          builder: (context, finalZoom, child) {
                            return Transform.scale(
                              scale: finalZoom,
                              child: child,
                            );
                          },
                          child: child,
                        );
                      },
                      child: child,
                    )
                  : const SizedBox.shrink();

              return Stack(
                children: [
                  // 扫描网格背景
                  Container(
                    width: 72,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          scanColor.withValues(alpha: 0.3),
                          scanColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: CustomPaint(painter: GridPainter(scanColor)),
                  ),
                  // 扫描线
                  Positioned(
                    left: 0,
                    right: 0,
                    top: progress * 96 - 4,
                    height: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            scanColor.withValues(alpha: 0.0),
                            scanColor.withValues(alpha: 0.8),
                            scanColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 🔧 扫描完成后显示卡牌内容（淡入 + 特写动画）
                  if (progress > 0.8)
                    Opacity(
                      opacity: (progress - 0.8) * 5, // 0.8-1.0区间渐变
                      child: completionProgress >= 1.0 ? zoomEffect : child,
                    ),
                ],
              );
            },
            child: SizedBox(width: 72, height: 96, child: _cardWidget(card)),
          ),
        // 弃牌扫描带动画
        if (_discardingCards.contains(card.id) &&
            _cardAnimationControllers.containsKey(card.id))
          AnimatedBuilder(
            animation: _cardAnimationControllers[card.id]!,
            builder: (context, child) {
              Color getScanColor() {
                switch (card.level) {
                  case 1:
                    return Colors.green.shade400;
                  case 2:
                    return Colors.blue.shade400;
                  case 3:
                    return Colors.purple.shade400;
                  case 4:
                    return Colors.orange.shade400;
                  case 5:
                    return Colors.red.shade400;
                  default:
                    return Colors.grey.shade400;
                }
              }

              final scanColor = getScanColor();
              final progress = _cardAnimationControllers[card.id]!.value;
              
              // 特写动画：扫描完成后放大弹跳
              final completionProgress = (progress - 0.8).clamp(0.0, 1.0) * 5;
              final zoomEffect = completionProgress >= 1.0
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.15),
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      builder: (context, zoom, child) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.15, end: 1.0),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          builder: (context, finalZoom, child) {
                            return Transform.scale(
                              scale: finalZoom,
                              child: child,
                            );
                          },
                          child: child,
                        );
                      },
                      child: child,
                    )
                  : const SizedBox.shrink();

              return Stack(
                children: [
                  // 扫描网格背景
                  Container(
                    width: 72,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          scanColor.withValues(alpha: 0.3),
                          scanColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: CustomPaint(painter: GridPainter(scanColor)),
                  ),
                  // 扫描线 - 从上往下移动
                  Positioned(
                    left: 0,
                    right: 0,
                    top: progress * 96 - 4,
                    height: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            scanColor.withValues(alpha: 0.0),
                            scanColor.withValues(alpha: 0.8),
                            scanColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 🔧 扫描完成后显示卡牌内容（淡入 + 特写动画）
                  if (progress > 0.8)
                    Opacity(
                      opacity: (progress - 0.8) * 5, // 0.8-1.0区间渐变
                      child: completionProgress >= 1.0 ? zoomEffect : child,
                    ),
                ],
              );
            },
            child: SizedBox(width: 72, height: 96, child: _cardWidget(card)),
          ),
      ],
    );
  }

  Widget _cardWidget(
    CardData c, {
    bool dragging = false,
    bool showCompleteAnimation = false,
  }) {
    Color getCardColor() {
      switch (c.level) {
        case 1:
          return Colors.green.shade400;
        case 2:
          return Colors.blue.shade400;
        case 3:
          return Colors.purple.shade400;
        case 4:
          return Colors.orange.shade400;
        case 5:
          return Colors.red.shade400;
        default:
          return Colors.grey.shade400;
      }
    }

    String primaryText() {
      if (c.effect != null) {
        return _formatEffect(c.effect!);
      }
      switch (c.type) {
        case CardType.attack:
          return "造成${c.value}伤害";
        case CardType.block:
          return "获得${c.value}格挡";
        case CardType.skill:
          return "技能";
        case CardType.power:
          return "能力";
      }
    }

    final base = getCardColor();
    final hsl = HSLColor.fromColor(base);
    final lighter =
        hsl.withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0)).toColor();
    final darker =
        hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor();
    final glow = base.withValues(alpha: dragging ? 0.9 : 0.5);

    return showCompleteAnimation
        ? TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 1.5, end: 1.0),
          curve: Curves.bounceOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 72,
                height: 96,
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [lighter, base, darker],
                  ),
                  borderRadius: BorderRadius.circular(8), // 增大圆角
                  border: Border.all(
                    color:
                        dragging
                            ? Colors.orange
                            : Colors.black.withValues(alpha: 0.3),
                    width: dragging ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: glow,
                      blurRadius: dragging ? 20 : 12,
                      spreadRadius: dragging ? 4 : 2,
                    ),
                  ],
                ),
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
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            "${c.cost}",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        primaryText(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )
        : Container(
          width: 72,
          height: 96,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [lighter, base, darker],
            ),
            borderRadius: BorderRadius.circular(8), // 增大圆角
            border: Border.all(
              color:
                  dragging
                      ? Colors.orange
                      : Colors.black.withValues(alpha: 0.3),
              width: dragging ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: glow,
                blurRadius: dragging ? 20 : 12,
                spreadRadius: dragging ? 4 : 2,
              ),
            ],
          ),
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "${c.cost}",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  primaryText(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  // 格式化效果描述
  String _formatEffect(String effect) {
    final effects = effect.split(' ');
    final result = <String>[];

    for (int i = 0; i < effects.length; i++) {
      final part = effects[i];
      switch (part) {
        case 'damage':
          if (i + 1 < effects.length) {
            result.add("造成${effects[i + 1]}伤害");
            i++;
          }
          break;
        case 'block':
          if (i + 1 < effects.length) {
            result.add("获得${effects[i + 1]}格挡");
            i++;
          }
          break;
        case 'draw':
          if (i + 1 < effects.length) {
            result.add("抽${effects[i + 1]}张牌");
            i++;
          }
          break;
        case 'energy':
          if (i + 1 < effects.length) {
            result.add("获得${effects[i + 1]}能量");
            i++;
          }
          break;
        case 'vulnerable':
          if (i + 1 < effects.length) {
            result.add("施加${effects[i + 1]}回合脆弱");
            i++;
          }
          break;
      }
    }

    return result.join('\\n');
  }

  // 关键区域：攻击冲锋效果（前进-短暂超冲-停留-回退）
  Widget _attackEffect(AttackEffect e) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
      builder: (_, t, __) {
        Offset pos;
        if (t < 0.3) {
          pos = Offset.lerp(e.start, e.end, t / 0.3)!;
        } else if (t < 0.35) {
          final overshoot = e.end + (e.end - e.start) * 0.03;
          pos = Offset.lerp(e.end, overshoot, (t - 0.3) / 0.05)!;
        } else if (t < 0.8) {
          pos = e.end;
        } else {
          pos = Offset.lerp(e.end, e.start, (t - 0.8) / 0.2)!;
        }

        final dir = (e.end - e.start);
        final mag = (dir.distance == 0) ? 1.0 : dir.distance;
        final unit = dir / mag;

        final scale =
            t < 0.35
                ? 1.0 + 0.06 * (t / 0.35)
                : t < 0.8
                ? 1.06
                : 1.0 + 0.06 * (1 - (t - 0.8) / 0.2);
        final rot =
            (e.attacker == player ? 0.04 : -0.04) *
            (t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2));

        return Stack(
          children: [
            for (int i = 1; i <= 3; i++)
              Positioned(
                left: pos.dx - unit.dx * i * 12,
                top: pos.dy - unit.dy * i * 12,
                child: Opacity(
                  opacity: (0.25 - (i * 0.06)).clamp(0.0, 1.0) as double,
                  child: _entityGhostWidget(
                    e.attacker,
                    scale: (0.98 - i * 0.06),
                    rotation: rot,
                  ),
                ),
              ),
            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: _entityGhostWidget(
                e.attacker,
                scale: scale,
                rotation: rot,
              ),
            ),
            if (t < 0.3)
              Positioned(
                left: pos.dx,
                top: pos.dy,
                child: Container(
                  width: e.attacker == player ? 80 : 100,
                  height: e.attacker == player ? 96 : 120,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 关键区域：攻击者幽灵模型（用于冲锋）
  Widget _entityGhostWidget(
    Entity e, {
    double scale = 1.0,
    double rotation = 0.0,
  }) {
    final baseColor =
        e == player ? const Color(0xFF152235) : const Color(0xFF1E2835);
    final child = Container(
      width: e == player ? 80 : 100,
      height: e == player ? 96 : 120,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF2A4158)),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            e == player ? Icons.person : Icons.pest_control,
            size: e == player ? 48 : 36,
            color: Colors.white70,
          ),
          const SizedBox(height: 8),
          Text(
            e.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
    return Opacity(
      opacity: 0.95,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }

  Widget _damagePopup(DamagePopup p) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: -40),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, offset, __) {
        final scale = offset < -20 ? 1.0 : 1.5 + (offset / 40);
        return Positioned(
          left: p.pos.dx,
          top: p.pos.dy + offset,
          child: Transform.scale(
            scale: scale,
            child: Text(
              "-${p.value}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                shadows: [Shadow(color: Colors.red, blurRadius: 10)],
              ),
            ),
          ),
        );
      },
    );
  }

  // 关键区域：护盾受击弹字
  Widget _blockDamagePopup(BlockPopup p) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: -30),
      duration: const Duration(milliseconds: 800),
      builder: (_, offset, __) {
        return Positioned(
          left: p.pos.dx,
          top: p.pos.dy + offset,
          child: Text(
            "-${p.value}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
        );
      },
    );
  }

  Widget _blockGainPopup(BlockGainPopup p) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: -30),
      duration: const Duration(milliseconds: 800),
      builder: (_, offset, __) {
        return Positioned(
          left: p.pos.dx,
          top: p.pos.dy + offset,
          child: Row(
            children: [
              const Icon(Icons.shield, size: 18, color: Colors.cyanAccent),
              const SizedBox(width: 4),
              Text(
                "+${p.value}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _healPopup(HealPopup p) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: -40),
      duration: const Duration(milliseconds: 800),
      builder: (_, offset, __) {
        return Positioned(
          left: p.pos.dx,
          top: p.pos.dy + offset,
          child: Row(
            children: [
              const Icon(Icons.favorite, size: 18, color: Colors.greenAccent),
              const SizedBox(width: 4),
              Text(
                "+${p.value}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 显示卡牌使用时的粒子效果
  void _showCardUseEffect(CardData card, Entity target) {
    // 根据卡牌类型添加不同的粒子效果
    switch (card.type) {
      case CardType.attack:
        _showAttackEffect(target);
        break;
      case CardType.block:
        _showBlockEffect(target);
        break;
      case CardType.skill:
      case CardType.power:
        _showSkillEffect(target);
        break;
    }
  }

  // 显示攻击效果
  void _showAttackEffect(Entity target) {
    // 添加攻击粒子效果
    setState(() {
      // 可以在这里添加攻击粒子效果的实现
    });
  }

  // 显示格挡效果
  void _showBlockEffect(Entity target) {
    // 添加格挡粒子效果
    setState(() {
      // 可以在这里添加格挡粒子效果的实现
    });
  }

  // 显示技能效果
  void _showSkillEffect(Entity target) {
    // 添加技能粒子效果
    setState(() {
      // 可以在这里添加技能粒子效果的实现
    });
  }

  // 关键区域：护盾破碎特效
  Widget _shieldBreakEffect(ShieldBreakEffect s) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (_, t, __) {
        final shards = [
          const Offset(-24, -18),
          const Offset(24, -18),
          const Offset(-28, 12),
          const Offset(28, 12),
          const Offset(0, 26),
        ];
        return Stack(
          children:
              shards.map((o) {
                return Positioned(
                  left: s.center.dx + o.dx * (1 + 0.3 * t),
                  top: s.center.dy + o.dy * (1 + 0.3 * t),
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0) as double,
                    child: Transform.rotate(
                      angle: o.dx.sign * 0.4 * t,
                      child: Icon(
                        Icons.shield,
                        size: 14 + 6 * (1 - t),
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _cardMotionWidget(CardMotion m) {
    final card = cardDatabase[m.cardId];
    if (card == null) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (_, t, __) {
        final x = m.start.dx + (m.end.dx - m.start.dx) * t;
        final y = m.start.dy + (m.end.dy - m.start.dy) * t;
        final s = 0.9 + 0.1 * t;
        final rot = (m.start.dy > m.end.dy ? -0.15 : 0.12) * (1 - t);
        final opacity = 0.85 + 0.15 * t;
        return Positioned(
          left: x,
          top: y,
          child: Transform.scale(
            scale: s,
            child: Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: rot,
                child: SizedBox(
                  width: 72,
                  height: 96,
                  child: _cardWidget(card, dragging: true),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
