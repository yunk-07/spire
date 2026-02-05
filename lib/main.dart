/**
 * 游戏主逻辑文件，包含战斗系统、卡牌渲染、Buff 说明浮层等核心 UI 与逻辑实现。
 */
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'card_data.dart';
import 'game_effects.dart';
import 'start_screen.dart';
import 'program_data.dart';
import 'map_screen.dart';
import 'level_data.dart';
import 'game_state.dart';
import 'character_data.dart';
// import 'laser_painter.dart';
// import 'slash_painter.dart';
import 'animation_constants.dart';
// import 'effect_styles.dart';
import 'theme_config.dart';
import 'effects_widgets.dart';
import 'brainchip_data.dart';

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
//    - 同步阶段(PlayerTurn)：显示扇形手牌视图(_fanHandView)
//    - 弃牌阶段(DiscardPhase)：显示横向选择界面(_discardPhaseView)
//    - 系统响应阶段(ProgramTurn)：显示扇形手牌视图
//    - 游戏结束(GameOver)：显示空状态
//
// 2. _fanHandView() - 扇形手牌视图（同步阶段主界面）
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
//      5. 进入系统响应阶段
//
// 8. 卡牌扫描动画流程（摸牌/弃牌阶段）
//    - 阶段1：扫描网格显示
//    - 阶段2：扫描线从上往下移动
//    - 阶段3：扫描进度>80%时卡牌内容淡入
//    - 阶段4：扫描完成，卡牌完全显示
// ============================================================================

/// 游戏阶段枚举
enum GamePhase {
  syncPhase, // 同步阶段（原同步阶段）
  discardPhase, // 弃牌阶段
  systemResponse, // 系统响应（原系统响应阶段）
  gameOver, // 游戏结束
}

enum SystemIntent { impact, encrypt, repair, summon }

void main() {
  runApp(const MyApp());
}

/// =====================
/// 实体
/// =====================

  class Entity {
    final String name;
    int hp;
    int maxHp;
    int block = 0;
    int fire = 0;
    final GlobalKey key = GlobalKey();
    String? id;
    int baseDamage = 8;
    SystemIntent? intent;
    int intentValue = 0;
    int tempStrength = 0;
    int sturdy = 0;

  // 状态效果
  int vulnerable = 0; // 漏洞暴露：受到额外冲击
  int weak = 0; // 虚弱：造成冲击减少
  int strength = 0; // 算力：增加造成的冲击
  int bloodStrength = 0; // 血液算力：专门记录血液被动的加成
  int curse = 0; // 诅咒：恶意代码层数

  Entity(this.name, this.hp, {int? maxHp}) : maxHp = maxHp ?? hp;
}

/// =====================
/// 系统冲击弹窗
/// =====================

enum PopupType {
  damage,      // 普通伤害 (红色)
  blockDamage, // 护盾吸收 (主题色)
  blockGain,   // 获得护盾 (主题色)
  heal,        // 恢复生命 (绿色)
  gold,        // 获得金币 (金色)
  crit,        // 暴击伤害 (橙红色，更大)
  blockTip,    // 格挡文字提示 (青色)
  status,      // 状态变化提示 (黄色)
}

class GamePopup {
  final String id;
  final String value;
  final Offset pos;
  final PopupType type;
  final DateTime startTime;
  // 随机偏移，让抛物线不完全一致
  final double drift;

  GamePopup({
    required this.value,
    required this.pos,
    required this.type,
  }) : id = DateTime.now().microsecondsSinceEpoch.toString(),
       startTime = DateTime.now(),
       drift = (Random().nextDouble() - 0.5) * 40;
}

/// 关键区域：全新冲击弹窗组件
/// 支持抛物线运动、缩放回弹和赛博朋克特效
class GamePopupWidget extends StatefulWidget {
  final GamePopup popup;
  const GamePopupWidget({super.key, required this.popup});

  @override
  State<GamePopupWidget> createState() => _GamePopupWidgetState();
}

class _GamePopupWidgetState extends State<GamePopupWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value;
        // 抛物线逻辑
        final dy = -100 * t + 50 * t * t; // 向上冲然后下落一点
        final dx = widget.popup.drift * t;
        
        // 缩放回弹逻辑
        double scale = 1.0;
        if (t < 0.2) {
          scale = 0.5 + t * 5.0; // 快速放大到 1.5
        } else if (t < 0.4) {
          scale = 1.5 - (t - 0.2) * 2.5; // 回弹到 1.0
        } else {
          scale = 1.0 - (t - 0.4) * 0.2; // 缓慢缩小
        }

        // 透明度淡出
        final opacity = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3).clamp(0.0, 1.0);

        Color textColor;
        List<Shadow> shadows;
        String prefix = "";
        IconData? icon;

        switch (widget.popup.type) {
          case PopupType.damage:
            textColor = Colors.redAccent;
            prefix = "-";
            shadows = [
              const Shadow(color: Colors.black, blurRadius: 4),
              Shadow(color: Colors.red.withValues(alpha: 0.8), blurRadius: 12),
            ];
            break;
          case PopupType.crit:
            textColor = const Color(0xFFFF4500); // 橙红色
            prefix = "CRIT -";
            scale *= 1.4; // 暴击更大
            shadows = [
              const Shadow(color: Colors.black, blurRadius: 4),
              const Shadow(color: Color(0xFFFF4500), blurRadius: 20),
              Shadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 2),
            ];
            break;
          case PopupType.blockDamage:
            textColor = const Color(0xFF00F0FF); // 赛博青
            prefix = "-";
            shadows = [
              const Shadow(color: Colors.black, blurRadius: 4),
              Shadow(color: const Color(0xFF00F0FF).withValues(alpha: 0.8), blurRadius: 12),
            ];
            break;
          case PopupType.blockGain:
            textColor = const Color(0xFF00F0FF);
            prefix = "+";
            icon = Icons.shield;
            shadows = [
              const Shadow(color: Colors.black, blurRadius: 4),
              Shadow(color: const Color(0xFF00F0FF).withValues(alpha: 0.8), blurRadius: 10),
            ];
            break;
          case PopupType.heal:
            textColor = Colors.greenAccent;
            prefix = "+";
            icon = Icons.favorite;
            shadows = [
              const Shadow(color: Colors.black, blurRadius: 4),
              Shadow(color: Colors.green.withValues(alpha: 0.8), blurRadius: 10),
            ];
            break;
          case PopupType.gold:
            textColor = const Color(0xFFFFD700); // 金色
            prefix = "+";
            icon = Icons.monetization_on;
            shadows = [
              const Shadow(color: Colors.black, blurRadius: 4),
              Shadow(color: const Color(0xFFFFD700).withValues(alpha: 0.8), blurRadius: 10),
            ];
            break;
          case PopupType.blockTip:
            textColor = const Color(0xFF00F0FF); // 赛博青
            prefix = "";
            shadows = [
              const Shadow(color: Colors.black, blurRadius: 4),
              Shadow(color: const Color(0xFF00F0FF).withValues(alpha: 0.8), blurRadius: 15),
            ];
            break;
          case PopupType.status:
            textColor = const Color(0xFFFFD700); // 金色/黄色
            prefix = "";
            shadows = [
              const Shadow(color: Colors.black, blurRadius: 4),
              Shadow(color: const Color(0xFFFFD700).withValues(alpha: 0.8), blurRadius: 12),
            ];
            break;
        }

        return Positioned(
          left: widget.popup.pos.dx + dx - 50, // 居中偏移
          top: widget.popup.pos.dy + dy,
          child: SizedBox(
            width: 150,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: textColor, size: 18),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        "$prefix${widget.popup.value}",
                        style: TextStyle(
                          color: textColor,
                          fontSize: widget.popup.type == PopupType.crit ? 32 : 24,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          shadows: shadows,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 关键区域：攻击特效
enum AttackEffectType {
  impact,   // 物理撞击
  laser,    // 激光射线
  slash,    // 斩击特效
  explosion,// 爆炸特效
  inject,   // 注入特效
}

class AttackEffect {
  final Entity attacker;
  final Offset start;
  final Offset end;
  final AttackEffectType type;
  AttackEffect(this.attacker, this.start, this.end, {this.type = AttackEffectType.impact});
}

class CardMotion {
  final String instanceId;
  final Offset start;
  final Offset end;
  CardMotion(this.instanceId, this.start, this.end);
}

/// 关键区域：防火墙崩溃特效
class ShieldBreakEffect {
  final Offset center;
  ShieldBreakEffect(this.center);
}

class AnimationService extends ChangeNotifier {
  final List<GamePopup> gamePopups = [];
  final List<AttackEffect> attacks = [];
  final List<GridPulse> gridPulses = []; // 网格脉冲效果列表
  final List<RoleEffect> roleEffects = []; // 角色专属特效列表
  final Set<Entity> protecting = {}; // 防御脉冲状态
  final Set<Entity> glitching = {}; // 数据过载/故障状态
  final Set<Entity> bouncing = {}; // 使用卡牌时的弹跳状态
  bool isScreenOverloaded = false; // 全局数据过载状态
  final List<CardMotion> motions = [];
  final List<ShieldBreakEffect> shieldBreaks = [];
  bool fireOverlayActive = false;
  DateTime? fireOverlayStart;
  bool hpDamageFlashActive = false;
  int? lastPlayerDamage;
  DateTime? lastPlayerDamageAt;
  Timer? _frameTimer;
  bool _hasActiveEffects() {
    return gamePopups.isNotEmpty ||
        attacks.isNotEmpty ||
        gridPulses.isNotEmpty ||
        roleEffects.isNotEmpty ||
        protecting.isNotEmpty ||
        glitching.isNotEmpty ||
        bouncing.isNotEmpty ||
        motions.isNotEmpty ||
        shieldBreaks.isNotEmpty ||
        fireOverlayActive ||
        hpDamageFlashActive;
  }
  void _ensurePump() {
    if (_frameTimer != null) return;
    _frameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_hasActiveEffects()) {
        _frameTimer?.cancel();
        _frameTimer = null;
        return;
      }
      notifyListeners();
    });
  }

  void showDamage(Entity target, int value, {bool isCrit = false}) {
    if (value <= 0) return; // 仅显示大于 0 的伤害

    final ctx = target.key.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(const Offset(50, 10));

    glitching.add(target); // 开启数据故障效果
    final p = GamePopup(
      value: value.toString(),
      pos: pos,
      type: isCrit ? PopupType.crit : PopupType.damage,
    );
    gamePopups.add(p);
    notifyListeners();
    _ensurePump();

    if (target.id == "接入单元") {
      hpDamageFlashActive = true;
      lastPlayerDamage = value;
      lastPlayerDamageAt = DateTime.now();
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 250), () {
        hpDamageFlashActive = false;
        notifyListeners();
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (lastPlayerDamageAt != null &&
            DateTime.now().difference(lastPlayerDamageAt!) >= const Duration(milliseconds: 900)) {
          lastPlayerDamage = null;
          lastPlayerDamageAt = null;
          notifyListeners();
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      glitching.remove(target); // 停止效果
      notifyListeners();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      gamePopups.remove(p);
      notifyListeners();
    });
  }

  void showBlockTip(Entity target) {
    final ctx = target.key.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(const Offset(50, -10)); // 位置稍高

    final p = GamePopup(
      value: "格挡",
      pos: pos,
      type: PopupType.blockTip,
    );
    gamePopups.add(p);
    notifyListeners();
    _ensurePump();

    Future.delayed(const Duration(milliseconds: 1200), () {
      gamePopups.remove(p);
      notifyListeners();
    });
  }

  // 播放角色专属特效
  void playRoleEffect(CharacterClass role, Offset pos) {
    final effect = RoleEffect(role, pos);
    roleEffects.add(effect);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1500), () {
      roleEffects.remove(effect);
      notifyListeners();
    });
  }

  // 关键区域：播放攻击轨迹（已移除旧版位移逻辑，仅保留特效）
  void playAttack(Entity from, Entity to, {AttackEffectType type = AttackEffectType.impact}) {
    final fctx = from.key.currentContext;
    final tctx = to.key.currentContext;
    if (fctx == null || tctx == null) return;

    final fbox = fctx.findRenderObject() as RenderBox?;
    final tbox = tctx.findRenderObject() as RenderBox?;
    if (fbox == null || tbox == null) return;
    final fpos = fbox.localToGlobal(const Offset(50, 40));
    final tpos = tbox.localToGlobal(const Offset(50, 40));

    final eff = AttackEffect(from, fpos, tpos, type: type);
    attacks.add(eff);
    notifyListeners();

    // 关键区域：在攻击瞬间触发全局数据过载效果
    Future.delayed(const Duration(milliseconds: 300), () {
      triggerScreenOverload();
    });

    Future.delayed(const Duration(milliseconds: 1000), () { // 增加总时长对齐 widget
      attacks.remove(eff);
      notifyListeners();
    });
  }

  void playCardMotion(String instanceId, Offset start, Offset end) {
    final m = CardMotion(instanceId, start, end);
    motions.add(m);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 650), () { // 对齐 _cardMotionWidget
      motions.remove(m);
      notifyListeners();
    });
  }

  void showBlockDamage(Entity target, int value) {
    if (value <= 0) return;
    final ctx = target.key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(const Offset(60, 120));
    final p = GamePopup(
      value: value.toString(),
      pos: pos,
      type: PopupType.blockDamage,
    );
    gamePopups.add(p);
    notifyListeners();
    _ensurePump();
    Future.delayed(const Duration(milliseconds: 1200), () {
      gamePopups.remove(p);
      notifyListeners();
    });
  }

  void playShieldBreak(Entity target) {
    final ctx = target.key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final center = box.localToGlobal(const Offset(60, 80));
    final s = ShieldBreakEffect(center);
    shieldBreaks.add(s);
    notifyListeners();
    _ensurePump();
    Future.delayed(const Duration(milliseconds: 600), () {
      shieldBreaks.remove(s);
      notifyListeners();
    });
  }

  void showBlockGain(Entity target, int value) {
    if (value <= 0) return;
    final ctx = target.key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(const Offset(60, 100));

    protecting.add(target); // 开启防御脉冲
    final p = GamePopup(
      value: value.toString(),
      pos: pos,
      type: PopupType.blockGain,
    );
    gamePopups.add(p);
    notifyListeners();
    _ensurePump();

    Future.delayed(const Duration(milliseconds: 500), () {
      protecting.remove(target); // 停止脉冲
      notifyListeners();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      gamePopups.remove(p);
      notifyListeners();
    });
  }

  void showHeal(Entity target, int value) {
    if (value <= 0) return;
    final ctx = target.key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(const Offset(50, 10));
    final p = GamePopup(
      value: value.toString(),
      pos: pos,
      type: PopupType.heal,
    );
    gamePopups.add(p);
    notifyListeners();
    _ensurePump();
    Future.delayed(const Duration(milliseconds: 1200), () {
      gamePopups.remove(p);
      notifyListeners();
    });
  }

  void showGold(Entity target, int value) {
    if (value <= 0) return;
    final ctx = target.key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(const Offset(50, -20)); // 在上方显示
    final p = GamePopup(
      value: value.toString(),
      pos: pos,
      type: PopupType.gold,
    );
    gamePopups.add(p);
    notifyListeners();
    _ensurePump();
    Future.delayed(const Duration(milliseconds: 1200), () {
      gamePopups.remove(p);
      notifyListeners();
    });
  }

  void showActionFeedback(Entity target) {
    bouncing.add(target);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 450), () {
      bouncing.remove(target);
      notifyListeners();
    });
  }

  // 关键区域：播放背景网格扩散脉冲
  void playGridPulse(Offset center) {
    final pulse = GridPulse(center);
    gridPulses.add(pulse);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1500), () {
      gridPulses.remove(pulse);
      notifyListeners();
    });
  }

  // 手动触发状态刷新
  void refresh() => notifyListeners();

  // 关键区域：显示状态变化提示（用于 Buff/Debuff 或特殊机制）
  void showStatusEffect(Entity target, String message, Color color) {
    final ctx = target.key.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(const Offset(50, -30)); // 在角色上方显示

    final p = GamePopup(
      value: message,
      pos: pos,
      type: PopupType.status, // 确保 PopupType 中有 status
    );
    gamePopups.add(p);
    notifyListeners();
    _ensurePump();

    Future.delayed(const Duration(milliseconds: 1500), () {
      gamePopups.remove(p);
      notifyListeners();
    });
  }

  void triggerScreenOverload() {
    isScreenOverloaded = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 400), () {
      isScreenOverloaded = false;
      notifyListeners();
    });
  }
  void triggerFireOverlay() {
    fireOverlayActive = true;
    fireOverlayStart = DateTime.now();
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1600), () {
      fireOverlayActive = false;
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

// 已迁移激光与斩击画笔到独立文件，移除旧定义

/// 关键区域：角色专属特效绘制（海浪线条等）




/// 关键区域：全局主题
ThemeData _darkTheme() {
  final base = ThemeData.dark();
  final tt = base.textTheme;
  final spire = (TextStyle s) => s.copyWith(fontFamily: 'SpireE', fontFamilyFallback: const ['SpireC']);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: GameState.getThemeColor(),
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
        fontFamily: 'SpireE',
        fontFamilyFallback: ['SpireC'],
      ),
      iconTheme: IconThemeData(color: Color(0xFF8FA3C0)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF101722),
        foregroundColor: GameState.getThemeColor(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
          fontFamily: 'SpireE',
          fontFamilyFallback: ['SpireC'],
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
        fontFamily: 'SpireE',
        fontFamilyFallback: ['SpireC'],
      ),
      contentTextStyle: const TextStyle(
        color: Color(0xFF8FA3C0),
        fontSize: 13,
        fontFamily: 'SpireE',
        fontFamilyFallback: ['SpireC'],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    textTheme: TextTheme(
      bodyLarge: tt.bodyLarge != null ? spire(tt.bodyLarge!) : null,
      bodyMedium: tt.bodyMedium != null ? spire(tt.bodyMedium!) : null,
      bodySmall: tt.bodySmall != null ? spire(tt.bodySmall!) : null,
      titleLarge: tt.titleLarge != null ? spire(tt.titleLarge!) : null,
      titleMedium: tt.titleMedium != null ? spire(tt.titleMedium!) : null,
      titleSmall: tt.titleSmall != null ? spire(tt.titleSmall!) : null,
      labelLarge: tt.labelLarge != null ? spire(tt.labelLarge!) : null,
      labelMedium: tt.labelMedium != null ? spire(tt.labelMedium!) : null,
      labelSmall: tt.labelSmall != null ? spire(tt.labelSmall!) : null,
      displayLarge: tt.displayLarge != null ? spire(tt.displayLarge!) : null,
      displayMedium: tt.displayMedium != null ? spire(tt.displayMedium!) : null,
      displaySmall: tt.displaySmall != null ? spire(tt.displaySmall!) : null,
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
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: CyberHoloGridPainter(
                      progress: t,
                      direction: CyberHoloDirection.vertical,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}



/// =====================
/// 战斗页面
/// =====================

class BattlePage extends StatefulWidget {
  /// 可选：来自地图/关卡的怪物ID列表
  final List<String>? programIds;

  /// 关卡ID（用于记录进度）
  final String? levelId;
  const BattlePage({super.key, this.programIds, this.levelId});
  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> with TickerProviderStateMixin {
  final anim = AnimationService();
  
  /// 获取当前游戏的主题色（基于脑机、职业状态等）
  Color _getThemeColor() {
    final isJianrenBoost = (characterData.characterClass == CharacterClass.jianren &&
        activePrograms.any((e) => e.hp > 0 && e.block <= 0));
    if (isJianrenBoost) return const Color(0xFFFFD700);
    
    final chipId = GameState.selectedBrainChipId;
    if (chipId != null) {
      final chip = brainChipDatabase[chipId] ?? brainChipPool.first;
      return Color(chip.themeColor);
    }
    return GameState.getThemeColor();
  }

  // 辅助函数：根据卡牌套装(Suite)确定视觉风格
  late AnimationController _waveCtrl;
  late AnimationController _chipDeployCtrl;
  late AnimationController _hpPulseCtrl;
  final GlobalKey _drawPileKey = GlobalKey();
  final GlobalKey _discardPileKey = GlobalKey();
  final Map<int, GlobalKey> _cardKeys = {};
  final Set<String> _dealingCards = {};
  final Set<String> _discardingCards = {};
  final Map<String, AnimationController> _cardAnimationControllers = {};

  final player = Entity("接入单元", GameState.playerHp, maxHp: GameState.playerMaxHp)
    ..strength = GameState.permanentStrength
    ..block = GameState.permanentBlock;
  late List<Entity> activePrograms;
  late CharacterData characterData; // 当前角色数据

  // 游戏状态提示
  String? _statusTip;
  Color? _statusTipColor;

  int energy = 3;
  int heatProgress = 0;

  // 回合制游戏状态
  GamePhase gamePhase = GamePhase.syncPhase; // 当前游戏阶段
  int turnCount = 1; // 周期计数
  bool isDiscardPhase = false; // 是否处于弃牌阶段
  bool hasDrawnCards = false; // 当前回合是否已抽牌
  bool isVictory = false; // 胜负标识
  bool _victoryRecorded = false; // 胜利记录一次
  CardSuite? _lastUsedSuite; // 几何职业：记录上一张使用的牌类别
  bool _yingshiInitBonusGranted = false;
  bool _interactionLocked = false;
  bool _resultScheduling = false;
  bool _chipBannerActive = false;
  bool _bossRewardSelected = false; // 是否已选择 Boss 奖励
  bool _isHolyReward = false; // 是否为神圣奖励（Boss战）
  String? _chipName;
  bool _quantumLinkUsedThisTurn = false; // 量子链路脑机本回合是否已使用过免费效果

  // Buff 详情查看状态
  String? _activeBuffName;
  String? _activeBuffDesc;

  static const Map<String, String> _buffExplanations = {
    "算力": "每层算力使攻击造成的伤害增加 1 点。",
    "临时算力": "每层临时算力使攻击造成的伤害增加 1 点，回合开始时 -5。",
    "血液算力": "血液被动的额外算力，基于损失生命值计算。",
    "虚弱": "虚弱状态下，造成的冲击伤害降低 25%。(层数代表持续回合)",
    "漏洞暴露": "漏洞暴露状态下，受到攻击时受到的伤害增加 50%。(层数代表持续回合)",
    "恶意代码": "每层恶意代码使受到攻击时额外受到的伤害增加 2 点。(每回合 -1 层)",
    "火焰": "回合结束后造成等于层数的伤害；护盾清零；每回合层数 -1。",
    "坚固": "拥有该状态时回合结束护盾不清零，每回合 -1。",
  };

  bool _isDraggingOverJudgementArea = false; // 是否正在向判定区拖动
  CardInstance? _previewCardInstance; // 当前正在预览的卡牌

  // 判定区组件
  Widget _judgementArea(Color themeColor) {
    return DragTarget<CardInstance>(
      onWillAccept: (instance) {
        final card = instance?.data;
        if (card == null) return false;
        final effectStr = card.effect ?? "";
        final baseAccept = (card.target == CardTarget.self || card.target == CardTarget.all);
        final faAccept = characterData.characterClass == CharacterClass.fa
            && card.target == CardTarget.enemy
            && (effectStr.contains('damage')
                || effectStr.contains('vulnerable')
                || effectStr.contains('weak')
                || effectStr.contains('curse'));
        final accept = baseAccept || faAccept;
        if (accept) {
          setState(() => _isDraggingOverJudgementArea = true);
        }
        return accept;
      },
      onAcceptWithDetails: (details) {
        final instance = details.data;
        setState(() => _isDraggingOverJudgementArea = false);
        
        final pulsePos = details.offset; // 使用释放时的位置作为扩散起点
        
        // 播放背景网格扩散特效
        anim.playGridPulse(pulsePos);
        
        // 使用卡牌
        useCard(instance, player);
        if (instance.data != null) {
          _showCardUseEffect(instance.data!, player);
        }
      },
      onLeave: (_) => setState(() => _isDraggingOverJudgementArea = false),
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = _isDraggingOverJudgementArea;
        final isDraggingAny = candidateData.isNotEmpty;
        
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: (isDraggingAny || isHighlighted) ? 1.0 : 0.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            decoration: BoxDecoration(
              color: isHighlighted 
                  ? themeColor.withValues(alpha: 0.15) 
                  : themeColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHighlighted 
                    ? themeColor 
                    : themeColor.withValues(alpha: 0.3),
                width: isHighlighted ? 2 : 1,
              ),
              boxShadow: [
                if (isHighlighted)
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CyberCornerPainter(
                        color: themeColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.system_update_alt_rounded,
                        color: isHighlighted 
                            ? themeColor 
                            : themeColor.withValues(alpha: 0.6),
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHighlighted ? "EXECUTE_SEQUENCE" : "READY_TO_UPLOAD",
                        style: TextStyle(
                          color: isHighlighted 
                              ? themeColor 
                              : themeColor.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          fontFamily: 'monospace',
                        ),
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
  }

  // 关键区域：左侧预览判定区
  Widget _cardPreviewZone(Color themeColor) {
    return Positioned(
      left: 0,
      top: 200,
      bottom: 0,
      width: 40,
      child: DragTarget<CardInstance>(
        onWillAccept: (instance) {
          if (instance != null) {
            setState(() {
              _previewCardInstance = instance;
            });
            return true;
          }
          return false;
        },
        onLeave: (instance) {
          setState(() {
            _previewCardInstance = null;
          });
        },
        onAcceptWithDetails: (details) {
          setState(() {
            _previewCardInstance = null;
          });
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  themeColor.withValues(alpha: isHovering ? 0.3 : 0.05),
                  themeColor.withValues(alpha: 0.0),
                ],
              ),
              border: Border(
                left: BorderSide(
                  color: themeColor.withValues(alpha: isHovering ? 0.8 : 0.2),
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  "放置显示卡牌详情",
                  style: TextStyle(
                    color: themeColor.withValues(alpha: isHovering ? 0.8 : 0.2),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 关键区域：放大预览悬浮窗
  Widget _magnifiedCardPreview(Color themeColor) {
    if (_previewCardInstance == null) return const SizedBox.shrink();
    final card = _previewCardInstance!.data;
    if (card == null) return const SizedBox.shrink();

    return Positioned(
      left: 45,
      top: 300,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(-15 * (1 - value), 0),
              child: Transform.scale(
                scale: 0.85 + 0.15 * value,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 168, // 84 * 2
                  height: 224, // 112 * 2
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.3),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _cardWidget(card, width: 168, height: 224),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 关键区域：重置本场战斗的数据统计
    GameStatistics.resetBattle();
    _hpPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _chipDeployCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    // 关键区域：根据地图节点构建系统程序
    activePrograms = _buildProgramsFromIds(widget.programIds);
    // 设置DSL效果执行器
    CardEffect.setExecutor(_executeCardEffect);
    // 获取当前角色数据
    characterData = characterDatabase[GameState.selectedCharacterId]!;
    // 焰心：跨关卡持久热量进度同步到战斗页
    heatProgress = GameState.heatProgress.clamp(0, 48);
    final chipId = GameState.selectedBrainChipId;
    if (chipId != null) {
      final chip = brainChipPool.firstWhere((c) => c.id == chipId, orElse: () => brainChipPool.first);
      _chipName = chip.name;
      _chipBannerActive = true;
      _chipDeployCtrl.forward();
      
      // 关键区域：确保脑机即时效果已应用（针对迁移或特殊获取路径）
      GameState.applyBrainChipInstantEffects(chipId);
      // 同步可能已改变的永久属性到当前战斗实体
      player.strength = GameState.permanentStrength;
      player.block = GameState.permanentBlock;
      player.maxHp = GameState.playerMaxHp;
      player.hp = min(player.hp, player.maxHp);
      
      // 关键区域：执行脑机 DSL 效果（过滤掉已在 applyBrainChipInstantEffects 中处理的永久性效果）
      if (chip.effect != null) {
        final filteredEffect = chip.effect!.split(';')
            .where((e) => !e.trim().startsWith('permanent_'))
            .join(';');
        if (filteredEffect.isNotEmpty) {
          CardEffect.execute(filteredEffect, null, null, this);
        }
      }
      
      Future.delayed(const Duration(milliseconds: 1600), () {
        _chipBannerActive = false;
        if (mounted) setState(() {});
      });
    }
    _applyStarFiveModifiers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_starFiveToast != null) {
        anim.refresh();
        CyberToast.show(context, _starFiveToast!);
        _starFiveToast = null;
      }
    });
    // 初始化抽牌堆
    drawPile.clear();
    for (final cardId in GameState.drawPile) {
      drawPile.add(CardInstance.create(cardId));
    }
    drawPile.shuffle();
    // 游戏开始时自动进入同步阶段
    startSyncPhase();
  }

  @override
  void dispose() {
    // 释放所有动画控制器
    _hpPulseCtrl.dispose();
    _waveCtrl.dispose();
    _chipDeployCtrl.dispose();
    for (final controller in _cardAnimationControllers.values) {
      controller.dispose();
    }
    _cardAnimationControllers.clear();
    super.dispose();
  }

  String? _starFiveToast;
  int _currentDifficulty() {
    final id = widget.levelId;
    if (id == null) return 1;
    for (final layer in GameProgress.levelLayers) {
      for (final level in layer) {
        if (level.id == id) {
          return level.difficulty.clamp(1, 5);
        }
      }
    }
    return 1;
  }

  void _applyStarFiveModifiers() {
    final diff = _currentDifficulty();
    if (diff != 5) return;
    final mods = <Map<String, dynamic>>[
      {"do": () { player.weak += 2; }, "desc": "玩家：虚弱×2"},
      {"do": () { for (final p in activePrograms) { p.strength += 3; } }, "desc": "敌方：算力+3"},
      {"do": () { player.curse += 1; }, "desc": "玩家：恶意代码×1"},
      {"do": () { player.vulnerable += 1; player.fire += 1; anim.triggerFireOverlay(); }, "desc": "敌方：算力+3"},
      {"do": () { for (final p in activePrograms) { p.block += 20; } }, "desc": "敌方：护盾+20"},
    ];
    final r = Random();
    final applied = <String>[];
    for (int i = 0; i < 2 && mods.isNotEmpty; i++) {
      final idx = r.nextInt(mods.length);
      final m = mods.removeAt(idx);
      (m["do"] as void Function())();
      applied.add(m["desc"] as String);
    }
    _starFiveToast = "☆5 扇区开局修正\n已应用：${applied.join(" · ")}";
  }

  // 根据怪物ID构建怪物实体
  List<Entity> _buildProgramsFromIds(List<String>? ids) {
    int _resolveLevelDifficulty() {
      final id = widget.levelId;
      if (id == null) return 1;
      for (final layer in GameProgress.levelLayers) {
        for (final level in layer) {
          if (level.id == id) {
            return level.difficulty.clamp(1, 5);
          }
        }
      }
      return 1;
    }
    final diff = _resolveLevelDifficulty();
    const hpFactors = [1.0, 1.2, 1.4, 1.6, 1.8];
    const dmgBonus = [0, 2, 4, 6, 8];
    final hpFactor = hpFactors[(diff - 1).clamp(0, hpFactors.length - 1)];
    final baseDmgBonus = dmgBonus[(diff - 1).clamp(0, dmgBonus.length - 1)];
    Entity _fromProgram(SecurityProgram data) {
      double typeHpFactor = 1.0;
      int typeDmgBonus = 0;
      switch (data.type) {
        case SystemType.elite:
          typeHpFactor = 1.15;
          typeDmgBonus = 2;
          break;
        case SystemType.boss:
          typeHpFactor = 1.25;
          typeDmgBonus = 4;
          break;
        case SystemType.normal:
          break;
      }
      final hp = (data.maxHp * hpFactor * typeHpFactor).ceil();
      final dmg = data.baseDamage + baseDmgBonus + typeDmgBonus;
      final e = Entity(data.name, hp, maxHp: hp);
      e.id = data.id;
      e.baseDamage = dmg;
      return e;
    }
    if (ids == null || ids.isEmpty) {
      final s = systemDatabase['slime'];
      final g = systemDatabase['goblin'];
      final k = systemDatabase['skeleton'];
      final ms = <Entity>[];
      if (s != null) {
        ms.add(_fromProgram(s));
      }
      if (g != null) {
        ms.add(_fromProgram(g));
      }
      if (k != null) {
        ms.add(_fromProgram(k));
      }
      return ms;
    }
    return ids.map((id) {
      final data = systemDatabase[id];
      if (data != null) {
        return _fromProgram(data);
      }
      return Entity(id, 30);
    }).toList();
  }

  /// DSL效果执行器实现
  void _executeCardEffect(
    String effect,
    CardData? card,
    dynamic target,
    dynamic battle,
  ) {
    // 分割多个效果（支持分号分隔）
    final effects = effect.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final bool isFa = characterData.characterClass == CharacterClass.fa;
    final bool isEnemyTarget = card?.target == CardTarget.enemy;
    final bool isAllTarget = card?.target == CardTarget.all;
    final bool hasEnemyEffect = effect.contains('damage') ||
        effect.contains('vulnerable') ||
        effect.contains('weak') ||
        effect.contains('curse');
    final bool faToAll = isFa && isEnemyTarget;
    final List<Entity> enemyTargets = (isAllTarget || faToAll)
        ? activePrograms.where((e) => e.hp > 0).toList()
        : (target != null ? [target as Entity] : <Entity>[]);
    final int repeatCount = (hasEnemyEffect && (isAllTarget || faToAll)) ? enemyTargets.length : 1;

    for (final effectPart in effects) {
      final parts = effectPart.split(' ');
      if (parts.isEmpty) continue;

      final command = parts[0];

      switch (command) {
        case 'damage':
          if (parts.length > 1) {
            final base = int.tryParse(parts[1]) ?? 0;
            if (isFa && (isAllTarget || faToAll || target != null)) {
              final box = context.findRenderObject() as RenderBox?;
              final size = box?.size;
              final pos = size != null ? Offset(size.width * 0.5, size.height * 0.9) : Offset.zero;
              anim.playRoleEffect(CharacterClass.fa, pos);
            }
            if (isAllTarget || faToAll) {
              final adj = (isFa && isAllTarget) ? (base * 1.25).ceil() : base;
              for (final enemy in enemyTargets) {
                _applyDamage(player, enemy, adj);
              }
            } else if (target != null) {
              _applyDamage(player, target as Entity, base);
            }
          }
          break;

        case 'block':
          if (parts.length > 1) {
            final value = int.tryParse(parts[1]) ?? 0;
            // 防御始终为固定值，不随目标数量倍增
            player.block += value;
            anim.showBlockGain(player, value);
          }
          break;

        case 'draw':
          if (parts.length > 1) {
            final count = int.tryParse(parts[1]) ?? 1;
            drawCards(isFa ? count * repeatCount : count);
          }
          break;

        case 'energy':
          if (parts.length > 1) {
            final value = int.tryParse(parts[1]) ?? 1;
            energy += value * repeatCount;
          }
          break;

        case 'vulnerable':
          if (parts.length > 1) {
            final turns = int.tryParse(parts[1]) ?? 1;
            if (isAllTarget || faToAll) {
              for (final enemy in enemyTargets) {
                enemy.vulnerable += turns;
              }
            } else if (target != null) {
              (target as Entity).vulnerable += turns;
            }
          }
          break;

        case 'weak':
          if (parts.length > 1) {
            final turns = int.tryParse(parts[1]) ?? 1;
            if (isAllTarget || faToAll) {
              for (final enemy in enemyTargets) {
                enemy.weak += turns;
              }
            } else if (target != null) {
              (target as Entity).weak += turns;
            }
          }
          break;

        case 'curse':
          if (parts.length > 1) {
            final turns = int.tryParse(parts[1]) ?? 1;
            if (isAllTarget || faToAll) {
              for (final enemy in enemyTargets) {
                enemy.curse += turns;
              }
            } else if (target != null) {
              (target as Entity).curse += turns;
            }
          }
          break;

        case 'strength':
          if (parts.length > 1) {
            final value = int.tryParse(parts[1]) ?? 1;
            player.strength += value * repeatCount;
          }
          break;
        case 'permanent_strength':
          if (parts.length > 1) {
            final value = int.tryParse(parts[1]) ?? 0;
            final total = value * repeatCount;
            GameState.permanentStrength += total;
            player.strength += total;
          }
          break;
        case 'temp_strength':
          if (parts.length > 1) {
            final value = int.tryParse(parts[1]) ?? 1;
            player.tempStrength += value * repeatCount;
          }
          break;
        case 'sturdy':
          if (parts.length > 1) {
            final turns = int.tryParse(parts[1]) ?? 1;
            // 坚固效果始终作用于自身
            player.sturdy += turns;
          }
          break;

        case 'self_damage':
          if (parts.length > 1) {
            final value = int.tryParse(parts[1]) ?? 1;
            // 自损不应该受算力加成，直接扣除生命值
            player.hp = max(0, player.hp - value);
            anim.showDamage(player, value);
            _playHitSound();
            GameState.playerHp = player.hp;

            // 关键区域：血液职业处理
            if (characterData.characterClass == CharacterClass.xueye) {
              // 1. 触发【生命回收】：自损伤害/10 恢复生命值（四舍五入）
              final healAmount = (value / 10.0).round();
              if (healAmount > 0) {
                player.hp = min(player.maxHp, player.hp + healAmount);
                anim.showHeal(player, healAmount);
                GameState.playerHp = player.hp;
              }
              // 2. 同步更新血液算力：损失生命/10（四舍五入）
              player.bloodStrength = ((player.maxHp - player.hp) / 10.0).round();
              
              // 触发视觉特效
              final ctx = context;
              final box = ctx.findRenderObject() as RenderBox?;
              if (box != null) {
                final center = box.size.center(Offset.zero);
                anim.playRoleEffect(CharacterClass.xueye, center);
              }
            }

            checkBattleResult();
          }
          break;

        case 'heal':
          if (parts.length > 1) {
            final value = int.tryParse(parts[1]) ?? 1;
            final total = value * repeatCount;
            player.hp = (player.hp + total).clamp(0, player.maxHp);
            anim.showHeal(player, total);
          }
          break;
        case 'max_hp_up':
          if (parts.length > 1) {
            final value = int.tryParse(parts[1]) ?? 0;
            final delta = value * repeatCount;
            if (delta != 0) {
              GameState.playerMaxHp = max(1, GameState.playerMaxHp + delta);
              player.maxHp = max(1, player.maxHp + delta);
              player.hp = (player.hp + delta).clamp(0, player.maxHp);
              GameState.playerHp = player.hp;
              anim.showHeal(player, delta);
            }
          }
          break;
        case 'max_hp_down':
          if (parts.length > 1) {
            final value = int.tryParse(parts[1]) ?? 0;
            final delta = value * repeatCount;
            if (delta != 0) {
              GameState.playerMaxHp = max(1, GameState.playerMaxHp - delta);
              player.maxHp = max(1, player.maxHp - delta);
              player.hp = min(player.hp, player.maxHp);
              GameState.playerHp = player.hp;
            }
          }
          break;
        case 'max_hp_mult':
          if (parts.length > 1) {
            final factor = double.tryParse(parts[1]) ?? 1.0;
            if (factor != 1.0) {
              final newMaxHp = (player.maxHp * factor).round().clamp(1, 999999);
              player.maxHp = newMaxHp;
              player.hp = min(player.hp, player.maxHp);
            }
          }
          break;
        case 'permanent_max_hp_mult':
          if (parts.length > 1) {
            final factor = double.tryParse(parts[1]) ?? 1.0;
            if (factor != 1.0) {
              GameState.playerMaxHp = (GameState.playerMaxHp * factor).round().clamp(1, 999999);
              player.maxHp = GameState.playerMaxHp;
              player.hp = min(player.hp, player.maxHp);
              GameState.playerHp = player.hp;
            }
          }
          break;
      }
    }
  }

  // 当前高亮的可攻击目标
  Entity? highlightedTarget;

  /// 手牌
  final List<CardInstance> hand = [];

  /// 抽牌堆
  final List<CardInstance> drawPile = [];

  /// 弃牌堆
  final List<CardInstance> discardPile = [];

  /// 抽牌数量
  int drawCount = 5;

  /// =====================
  /// 使用卡牌
  /// =====================

  void useCard(CardInstance instance, Entity? target) {
    final card = instance.data;
    if (card == null) return;

    int effectiveCost = card.cost;
    // 脑机被动：量子链路接口 —— 每回合第一张消耗 2 点能量的卡牌变为 0 消耗
    if (GameState.selectedBrainChipId == 'quantum_link' && card.cost == 2 && !_quantumLinkUsedThisTurn) {
      effectiveCost = 0;
      _quantumLinkUsedThisTurn = true;
      _showStatusTip("【量子链路】指令开销减免", const Color(0xFF00AAFF));
    }

    if (energy < effectiveCost) {
      // 显示能量不足提示

      _showStatusTip("能量不足，无法使用该卡牌", Colors.redAccent);
      return;
    }

    energy -= effectiveCost;
    if (characterData.characterClass == CharacterClass.yanxin) {
      heatProgress = (heatProgress + card.cost).clamp(0, 48);
      GameState.heatProgress = heatProgress;
    }
    final idx = hand.indexOf(instance);
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
    hand.remove(instance);

    // 使用后的卡牌进入弃牌堆
    discardPile.add(instance);

    // 关键区域：浪潮职业被动【涌动】—— 手牌为空时恢复能量并摸牌
    if (characterData.characterClass == CharacterClass.langchao && hand.isEmpty) {
      energy = (energy + 2).clamp(0, 99);
      drawCards(2);
      _showStatusTip("【涌动】能量回收 +2，下行摸牌 +2", const Color(0xFF4DCCFF));
      
      // 触发海浪线条特效
      final ctx = context;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null) {
        final center = box.size.center(Offset.zero);
        anim.playRoleEffect(CharacterClass.langchao, center);
      }
    }

    // 关键区域：几何职业被动【结构链路】—— 连续使用同类别卡牌获得能量并摸牌
    if (characterData.characterClass == CharacterClass.jihe) {
      if (_lastUsedSuite != null && card.suite == _lastUsedSuite) {
        energy = (energy + 1).clamp(0, 99);
        drawCards(1);
        _showStatusTip("【结构链路】能量回收 +1，数据读取 +1", const Color(0xFF00FF00));
        
        // 触发几何六边形网格特效
        final ctx = context;
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null) {
          final center = box.size.center(Offset.zero);
          anim.playRoleEffect(CharacterClass.jihe, center);
        }
      }
      _lastUsedSuite = card.suite;
    }

    // 关键区域：林职业被动【稳态增压】—— 每使用一张牌获得 5 点临时算力
    if (characterData.characterClass == CharacterClass.lin) {
      player.tempStrength += 5;
      _showStatusTip("【稳态增压】临时算力 +5", _getThemeColor());
      final ctx = context;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null) {
        final center = box.size.center(Offset.zero);
        anim.playRoleEffect(CharacterClass.lin, center);
      }
    }

    // 关键区域：虚行职业被动【虚空共鸣】—— 使用量子卡牌时施加诅咒
    if (characterData.characterClass == CharacterClass.xuxing && card.suite == CardSuite.quantum) {
      final targets = activePrograms.where((p) => p.hp > 0).toList();
      if (targets.isNotEmpty) {
        final randomTarget = targets[Random().nextInt(targets.length)];
        randomTarget.curse += 1;
        _showStatusTip("【虚空共鸣】注入恶意代码", const Color(0xFF9933FF));
        
        // 触发虚行故障方块特效
        final ctx = context;
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null) {
          final center = box.size.center(Offset.zero);
          anim.playRoleEffect(CharacterClass.xuxing, center);
        }
      }
    }

    // 触发玩家行动反馈动画（小弹跳）
    anim.showActionFeedback(player);

    // 关键区域：ANN接替思维脑机被动 —— 手牌小于7，每使用一张牌摸一张牌
    if (GameState.selectedBrainChipId == 'ann_replacement' && hand.length < 7) {
      _randomDrawCards(count: 1);
      _showStatusTip("【ANN】神经网络自动补牌", const Color(0xFF9D00FF));
    }

    // 使用DSL系统处理卡牌效果
          if (card.effect != null) {
            // 关键区域：根据卡牌属性选择攻击特效类型
            AttackEffectType effectType = AttackEffectType.impact;
            if (card.suite == CardSuite.quantum) {
              effectType = AttackEffectType.laser;
            } else if (card.suite == CardSuite.overload || card.id == 'bludgeon') {
              effectType = AttackEffectType.explosion;
            } else if (card.id == 'heavy_blade' || card.id == 'double_hit' || card.id == 'burning_slash' || card.id == 'jianren_strike') {
              effectType = AttackEffectType.slash;
            } else if (card.id == 'sneaky_strike' || card.id == 'curse_mark') {
              effectType = AttackEffectType.inject;
            }
            // 剑刃：移除旧版斩击特效，改用刀痕切网格（由角色特效层渲染）
            if (characterData.characterClass == CharacterClass.jianren && effectType == AttackEffectType.slash) {
              effectType = AttackEffectType.impact;
            }

            // 关键区域：攻击动画触发
            if (target != null) {
              final shouldAttackAnim = (card.type == CardType.exploit && (
                card.effect!.contains('damage') ||
                card.effect!.contains('weak') ||
                card.effect!.contains('vulnerable')
              ));
              if (shouldAttackAnim) {
                anim.playAttack(player, target, type: effectType);
              }
              // 添加攻击音效
              _playAttackSound();
              
              // 优化玩家攻击流程：等待动画到达冲击点后再执行效果
              Future.delayed(const Duration(milliseconds: 300), () {
                CardEffect.execute(card.effect!, card, target, this);
                checkBattleResult();
                setState(() {});
              });
            } else {
              CardEffect.execute(card.effect!, card, target, this);
            }
          }
    // 增加使用卡牌统计
    GameStatistics.totalCardsUsed++;
    GameStatistics.battleCardsUsed++;

    // 重置高亮目标
    highlightedTarget = null;
    
    // 关键区域：更新怪物意图（可能受刚施加的状态影响，但只有30%几率改变）
    _rollSystemIntents(isTurnStart: false);

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

  // 关键区域：掉落金币逻辑
  void _dropGold(Entity monster) {
    final random = Random();
    final nationDifficulty = GameProgress.currentNation.difficulty;
    // 基础金币 5-10
    double gold = (5 + random.nextInt(6)).toDouble();
    // 难度加成
    gold += nationDifficulty * 3;
    // 怪物强度加成 (每10点HP加1金币)
    gold += monster.maxHp / 10;
    
    // 随机浮动 80% - 120%
    int finalGold = (gold * (0.8 + random.nextDouble() * 0.4)).floor();
    
    if (finalGold > 0) {
      GameState.playerGold += finalGold;
      _showStatusTip("获得信用点: +$finalGold", const Color(0xFFFFD700));
      anim.showGold(monster, finalGold);
    }
  }

  void _applyDamage(Entity? attacker, Entity target, int baseValue, {bool isFinal = false}) {
     if (baseValue <= 0) return;
     
     double finalDamage = baseValue.toDouble();
     
      if (!isFinal) {
         // 关键区域：攻击者状态影响
        if (attacker != null) {
          // 算力加成：直接增加基础冲击力
          int effectiveStrength = attacker.strength;
          effectiveStrength += attacker.tempStrength;
          
          // 关键区域：血液职业被动【血债血偿】
          if (attacker == player && characterData.characterClass == CharacterClass.xueye) {
            // 每损失 10 点生命值增加 1 点算力（四舍五入）
            final lostHp = attacker.maxHp - attacker.hp;
            attacker.bloodStrength = (lostHp / 10.0).round();
            effectiveStrength += attacker.bloodStrength;
          } else {
            attacker.bloodStrength = 0;
          }
         
         finalDamage += effectiveStrength;
          if (attacker == player && characterData.characterClass == CharacterClass.jianren &&
              activePrograms.any((e) => e.hp > 0 && e.block <= 0)) {
            finalDamage = (finalDamage * 1.24).ceilToDouble();
          }
         
         // 虚弱状态：输出降低 25% (统一逻辑：层数代表持续时间，效果固定为 0.75x)
        if (attacker.weak > 0) {
          finalDamage *= 0.75;
        }
       }
       
      // 关键区域：受击者状态影响 (统一逻辑：层数代表持续时间，效果固定为 1.5x)
       if (target.vulnerable > 0) {
         finalDamage *= 1.5;
       }
       
       // 诅咒/恶意代码：每层额外增加冲击
       if (target.curse > 0) {
         finalDamage += target.curse * 2;
       }
     }
 
     int remaining = finalDamage.floor();
    if (remaining <= 0 && baseValue > 0) remaining = 1; // 至少造成1点冲击
    
      if (target.block > 0) {
        final absorbed = remaining.clamp(0, target.block);
        target.block -= absorbed;
        remaining -= absorbed;
        if (absorbed > 0) {
          anim.showBlockDamage(target, absorbed);
          _playBlockSound();
          GameStatistics.totalDamageBlocked += absorbed;
          GameStatistics.battleDamageBlocked += absorbed;
        }
        if (target.block == 0 && absorbed > 0) {
          anim.playShieldBreak(target);
          anim.showBlockTip(target); // 弹出“格挡”提示
          if (identical(target, player) && characterData.characterClass == CharacterClass.yingshi) {
            player.tempStrength += 16;
          }
        }
      }
      
      if (remaining > 0) {
      final beforeHp = target.hp;
      target.hp = max(0, target.hp - remaining);
      
      // 关键区域：怪物被击败时掉落金币
      if (beforeHp > 0 && target.hp == 0 && !identical(target, player)) {
        _dropGold(target);
      }

      if (identical(target, player) && characterData.characterClass == CharacterClass.yingshi) {
        final gain = (max(0, beforeHp - target.hp) ~/ 5);
        if (gain > 0) player.tempStrength += gain;
      }
      
      // 记录玩家受损状态（用于影蚀被动等）
    // if (identical(target, player)) {
    //   _playerTookDamageThisTurn = true;
    // }

      anim.showDamage(target, remaining);
      _playHitSound();
      GameStatistics.totalDamageDealt += remaining;
      GameStatistics.battleDamageDealt += remaining;
    }
    
    if (identical(target, player)) {
      GameState.playerHp = target.hp;
    }
    if (attacker == player && characterData.characterClass == CharacterClass.yingshi && target.hp == 0) {
      player.tempStrength += target.maxHp;
    }
    if (attacker == player && characterData.characterClass == CharacterClass.jianren && target.hp == 0) {
      player.hp = min(player.maxHp, player.hp + 50);
      anim.showHeal(player, 50);
      GameState.playerHp = player.hp;
    }

    // 关键区域：血液职业被动【生命回收】—— 造成伤害/10 恢复生命值（四舍五入）
    if (attacker == player && characterData.characterClass == CharacterClass.xueye && remaining > 0) {
      final healAmount = (remaining / 10.0).round();
      if (healAmount > 0) {
        player.hp = min(player.maxHp, player.hp + healAmount);
        anim.showHeal(player, healAmount);
        GameState.playerHp = player.hp;
        
        // 触发血液脉冲特效
        final ctx = context;
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null) {
          final center = box.size.center(Offset.zero);
          anim.playRoleEffect(CharacterClass.xueye, center);
        }
      }
    }
  }

  // 播放受击音效
  void _playHitSound() {
    // 可以在这里添加受击音效的实现
  }

  /// =====================
  /// 抽牌
  /// =====================

  void drawCards([int? count]) {
    if (drawPile.isEmpty) {
      // 如果抽牌堆为空，将弃牌堆洗入抽牌堆
      drawPile.addAll(discardPile);
      discardPile.clear();
      // 洗牌
      drawPile.shuffle();
    }

    final actualCount = count ?? drawCount;
    final cardsToDraw = actualCount.clamp(0, drawPile.length);
    final newCards = <CardInstance>[];
    for (int i = 0; i < cardsToDraw; i++) {
      final instance = drawPile.removeAt(0);
      hand.add(instance);
      newCards.add(instance);
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
  /// 结束同步
  /// =====================

  /// 开始系统响应（原系统响应阶段）
  void startSystemResponse() async {
    gamePhase = GamePhase.systemResponse;
    isDiscardPhase = false;

    // 系统程序行动逻辑：改为异步轮流执行
    await _systemActions();

    // 若在系统响应结束后已产生胜负（例如火焰标记结算致胜），则不进入下一回合
    if (gamePhase == GamePhase.gameOver) {
      setState(() {});
      return;
    }

    // 系统响应结束后进入下一同步周期
    turnCount++;
    startSyncPhase();
  }

  /// =====================
  /// 回合制游戏规则系统
  /// =====================

  double _getMonsterScalingFactor() {
    if (turnCount >= 20) return 2.0;
    if (turnCount >= 15) return 1.6;
    if (turnCount >= 10) return 1.3;
    return 1.0;
  }

  /// 开始同步阶段（原同步阶段）
  void startSyncPhase() {
    gamePhase = GamePhase.syncPhase;
    isDiscardPhase = false;
    hasDrawnCards = false;
    if (player.sturdy > 0) {
      player.sturdy = max(0, player.sturdy - 1);
    } else {
      player.block = 0;
    }
    if (characterData.characterClass == CharacterClass.jianren) {
      player.sturdy += 1;
    }
    _lastUsedSuite = null; // 重置几何职业的上一张牌类别
    _quantumLinkUsedThisTurn = false; // 重置量子链路脑机使用记录

    // 每周期开始时重置能量（能量）为固定值
    energy = 3;

    // 脑机被动：故障频率处理器 —— 50% 概率额外获得 1 点能量
    if (GameState.selectedBrainChipId == 'glitch_processor' && Random().nextDouble() < 0.5) {
      energy += 1;
      _showStatusTip("【故障频率】系统随机超频 +1 能量", const Color(0xFFE26CFF));
    }

    int drawBonus = 0;
    if (player.tempStrength > 0) {
      player.tempStrength = max(0, player.tempStrength - 5);
    }
    for (final e in activePrograms) {
      if (e.tempStrength > 0) {
        e.tempStrength = max(0, e.tempStrength - 5);
      }
    }
    if (characterData.characterClass == CharacterClass.yingshi &&
        activePrograms.where((e) => e.hp > 0).length == 1 &&
        !_yingshiInitBonusGranted) {
      player.tempStrength += 24;
      player.vulnerable += 1;
      _yingshiInitBonusGranted = true;
    }
    // _playerTookDamageThisTurn = false; // 重置受损记录

    // 同步阶段开始时自动抽牌：随机获取数据包
    _randomDrawCards(bonus: drawBonus);
    hasDrawnCards = true;
    
    // 关键区域：记录总回合数
    GameStatistics.totalTurns++;
    GameStatistics.battleTurns++;

    // 关键区域：同步阶段开始时结算玩家状态
    if (player.vulnerable > 0) player.vulnerable--;
    if (player.weak > 0) player.weak--;
    if (player.curse > 0) player.curse--;
    
    // 关键区域：结算玩家身上的火焰（持续伤害）
    if (player.hp > 0 && player.fire > 0) {
      if (player.block > 0) {
        player.block = 0;
        anim.playShieldBreak(player);
      }
      _applyDamage(player, player, player.fire, isFinal: true);
      player.fire = max(0, player.fire - 1);
    }

    _rollSystemIntents(isTurnStart: true);

    setState(() {});
  }

  /// 随机抽牌逻辑：随机抽取随机张牌
  void _randomDrawCards({int bonus = 0, int? count}) {
    if (drawPile.isEmpty) {
      drawPile.addAll(discardPile);
      discardPile.clear();
      drawPile.shuffle();
    }

    final random = Random();
    int cardsToDraw;
    
    if (count != null) {
      cardsToDraw = count;
    } else {
      cardsToDraw =
          random.nextInt(
                characterData.maxDrawPerTurn - characterData.minDrawPerTurn + 1,
              ) +
              characterData.minDrawPerTurn +
              bonus;
    }
    
    final actualDrawCount = cardsToDraw.clamp(1, drawPile.length);

    final newCards = <CardInstance>[];
    for (int i = 0; i < actualDrawCount; i++) {
      final instance = drawPile.removeAt(0);
      hand.add(instance);
      newCards.add(instance);
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
          final instance = hand[idx];
          _dealingCards.add(instance.instanceId);
          // 创建动画控制器
          _cardAnimationControllers[instance.instanceId] = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          );
          // 启动动画
          _cardAnimationControllers[instance.instanceId]?.forward();
          setState(() {});
          // 移除原有的发牌动画，改为扫描带显现
          Future.delayed(const Duration(milliseconds: 820), () {
            _dealingCards.remove(instance.instanceId);
            // 释放动画控制器
            _cardAnimationControllers[instance.instanceId]?.dispose();
            _cardAnimationControllers.remove(instance.instanceId);
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

  /// 系统程序行动逻辑
  Future<void> _systemActions() async {
    // 关键区域：系统响应阶段开始时结算怪物的状态（护盾不再自动清零）
    for (final program in activePrograms) {
      if (program.hp > 0) {
        if (program.sturdy > 0) {
          program.sturdy = max(0, program.sturdy - 1);
        }
      }
    }
    setState(() {});

    // 关键区域：使用 List.from 创建副本进行迭代，防止召唤新怪物时触发 ConcurrentModificationError
    final programsToAct = List<Entity>.from(activePrograms);
    
    for (final program in programsToAct) {
      if (program.hp > 0) {
        // 每个怪物行动前稍微停顿，增加层次感
        await Future.delayed(const Duration(milliseconds: 400));
        
        switch (program.intent) {
          case SystemIntent.impact:
            await _systemAttackPlayer(program, predicted: program.intentValue);
            break;
          case SystemIntent.encrypt:
            _systemDefend(program, value: program.intentValue);
            // 防御动作也等待一下动画
            await Future.delayed(const Duration(milliseconds: 500));
            break;
          case SystemIntent.repair:
            _systemHeal(program, amount: program.intentValue);
            // 修复动作等待
            await Future.delayed(const Duration(milliseconds: 500));
            break;
          case SystemIntent.summon:
            await _systemSummon(program);
            break;
          default:
            await _systemAttackPlayer(program);
            break;
        }
        program.intent = null;
        program.intentValue = 0;
        
        // 关键区域：怪物状态衰减
        if (program.vulnerable > 0) program.vulnerable--;
        if (program.weak > 0) program.weak--;
        if (program.curse > 0) program.curse--;
        
        // 关键区域：每个怪物行动完后更新UI
        setState(() {});
        
        // 检查玩家是否死亡
        if (player.hp <= 0) break;
      }
    }

    if (characterData.characterClass == CharacterClass.yanxin) {
      // 关键区域：使用 List.from 防止迭代期间修改集合
      final fireTargets = List<Entity>.from(activePrograms);
      for (final program in fireTargets) {
        if (program.hp > 0 && program.fire > 0) {
          if (program.block > 0) {
            program.block = 0;
            anim.playShieldBreak(program);
          }
          _applyDamage(player, program, program.fire, isFinal: true);
          program.fire = max(0, program.fire - 1);
        }
      }
    }

    // 关键区域：系统响应结束后检查渗透结果
    checkBattleResult();
    setState(() {});
  }

  /// 怪物冲击接入单元
  Future<void> _systemAttackPlayer(Entity program, {int? predicted}) async {
    // 关键区域：赌场经理伤害激增视觉反馈
    if (program.id == "casino_boss" && activePrograms.length >= 6) {
      _showStatusTip("【赌场经理】算力超载：全功率冲击中！", Colors.redAccent);
      anim.showStatusEffect(program, "OVERLOAD_MODE", Colors.redAccent);
      await Future.delayed(const Duration(milliseconds: 400));
    }

    // 使用预测值（即 intentValue），它已经包含了算力、虚弱、漏洞暴露和诅咒的计算
    int totalDamage = predicted ?? program.intentValue;
    
    // 如果没有预测值且 intentValue 为 0，则进行保底计算（通常不应发生）
    if (totalDamage <= 0) {
      final random = Random();
      double dmg = (program.baseDamage + (turnCount ~/ 3) + random.nextInt(3)).toDouble();
      dmg *= _getMonsterScalingFactor(); // 应用回合增强
      dmg += program.strength;
      if (program.weak > 0) dmg *= 0.75;
      if (player.vulnerable > 0) dmg *= 1.5;
      dmg += player.curse * 2;
      totalDamage = dmg.floor();
    }

    // 关键区域：怪物攻击动画
    anim.playAttack(program, player);

    // 等待攻击动画冲击点
    await Future.delayed(const Duration(milliseconds: 300));
    // 使用 isFinal: true，因为所有状态影响已经在计算 totalDamage 时处理过了
    _applyDamage(program, player, totalDamage, isFinal: true);
    
    // 等待动画收回
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// 怪物恢复生命值
  void _systemHeal(Entity program, {int? amount}) {
    final random = Random();
    final healAmount = amount ?? ((random.nextInt(5) + 3) * _getMonsterScalingFactor()).floor();
    program.hp = (program.hp + healAmount).clamp(0, program.maxHp);

    anim.showHeal(program, healAmount);
  }

  void _systemDefend(Entity program, {int? value}) {
    final random = Random();
    final v = value ?? ((3 + (turnCount ~/ 3) + random.nextInt(4)) * _getMonsterScalingFactor()).floor();
    program.block += v;
    anim.showBlockGain(program, v);
  }

  /// 赌场老板特殊机制：召唤新的怪兽
  Future<void> _systemSummon(Entity boss) async {
    // 关键区域：检查整体上限 6
    if (activePrograms.length >= 6) {
      _showStatusTip("【赌场经理】调度指令被拦截：系统负载已达上限", Colors.redAccent);
      await Future.delayed(const Duration(milliseconds: 600));
      return;
    }

    // 关键区域：召唤动作占用当前怪物的完整回合
    _showStatusTip("【赌场经理】正在调度安保程序...", const Color(0xFFFFD700));
    
    // 播放召唤动画/提示
    await Future.delayed(const Duration(milliseconds: 600));

    // 创建新的怪兽：赌场保镖
    final securityData = systemDatabase["casino_security"]!;
    final security = Entity(securityData.name, securityData.maxHp);
    security.id = securityData.id;
    security.baseDamage = securityData.baseDamage;
    security.maxHp = securityData.maxHp;
    security.hp = securityData.maxHp;

    setState(() {
      activePrograms.add(security);
    });

    // 为新召唤的怪兽立即roll一个意图
    _rollSystemIntents();
    
    // 播放入场动画
    anim.showStatusEffect(security, "增援程序已接入", const Color(0xFFFFD700));
    
    // 召唤占用回合，所以这里需要一个明显的停顿，且不再执行其他动作
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  void _rollSystemIntents({bool isTurnStart = false}) {
    final random = Random();
    for (final m in activePrograms) {
      if (m.hp <= 0) {
        m.intent = null;
        m.intentValue = 0;
        continue;
      }

      // 决定意图类型
      bool shouldChangeIntentType = isTurnStart || m.intent == null || random.nextDouble() < 0.3;
      
      if (shouldChangeIntentType) {
        // 赌场老板特殊机制：如果场上怪兽小于3，且总数未达上限6，则有较高概率召唤新怪兽
        if (m.id == "casino_boss" && 
            activePrograms.where((e) => e.hp > 0).length < 3 &&
            activePrograms.length < 6) {
          m.intent = SystemIntent.summon;
        } else {
          final lowHp = m.hp < m.maxHp * 0.3;
          final p = random.nextDouble();
          if (lowHp && p < 0.4) {
            m.intent = SystemIntent.repair;
          } else if (p < 0.25) {
            m.intent = SystemIntent.encrypt;
          } else {
            m.intent = SystemIntent.impact;
          }
        }
      }

      // 无论意图类型是否改变，都重新计算意图数值以反映最新的状态效果
      double scalingFactor = _getMonsterScalingFactor();

      if (m.intent == SystemIntent.repair) {
        m.intentValue = ((random.nextInt(5) + 3) * scalingFactor).floor();
      } else if (m.intent == SystemIntent.summon) {
        m.intentValue = 0; // 召唤动作没有数值
      } else if (m.intent == SystemIntent.encrypt) {
        m.intentValue = ((3 + (turnCount ~/ 3) + random.nextInt(4)) * scalingFactor).floor();
      } else if (m.intent == SystemIntent.impact) {
        double dmg = (m.baseDamage + (turnCount ~/ 3) + random.nextInt(3)).toDouble();
        
        // 关键区域：赌场经理特殊机制 - 当保镖达到上限 6 时，伤害激增
        if (m.id == "casino_boss" && activePrograms.length >= 6) {
          dmg *= 2.5; // 伤害提升 2.5 倍
        }
        
        // 增加回合数增强
        dmg *= scalingFactor;
        
        // 考虑怪物的算力和虚弱 (统一逻辑)
        dmg += m.strength;
        if (m.weak > 0) dmg *= 0.75;
        
        // 考虑玩家的漏洞暴露(vulnerable)和诅咒
        if (player.vulnerable > 0) dmg *= 1.5;
        dmg += player.curse * 2;
        
        m.intentValue = dmg.floor();
      }

      // 回合增强提示
      if (isTurnStart && scalingFactor > 1.0) {
        String level = turnCount >= 20 ? "III" : (turnCount >= 15 ? "II" : "I");
        anim.showStatusEffect(m, "系统迭代 $level: 数值 x$scalingFactor", Colors.orangeAccent);
      }
    }
  }

  /// 检查能量耗尽自动进入弃牌阶段
  void checkEnergyExhaustion() {
    if (energy <= 0 && gamePhase == GamePhase.syncPhase && !isDiscardPhase) {
      startDiscardPhase();
    }
  }

  /// 完成弃牌阶段
  /// 完成弃牌阶段并进入系统响应
  Future<void> completeDiscardPhase({int discardedCount = 0}) async {
    int totalDiscarded = discardedCount;
    if (hand.length > 1) {
      // 如果手牌超过1张，需要玩家手动选择保留哪张
      // 这里暂时自动保留第一张，弃掉其他
      final instanceToKeep = hand[0];
      totalDiscarded += (hand.length - 1);
      for (int idx = 1; idx < hand.length; idx++) {
        final instance = hand[idx];
        final key = _cardKeys[idx];
        final ctx = key?.currentContext;
        final box = ctx?.findRenderObject() as RenderBox?;
        final start = box?.localToGlobal(const Offset(36, 48));
        final dctx = _discardPileKey.currentContext;
        final dbox = dctx?.findRenderObject() as RenderBox?;
        final end = dbox?.localToGlobal(const Offset(50, 30));
        if (start != null && end != null) {
          _discardingCards.add(instance.instanceId);
          // 创建动画控制器
          _cardAnimationControllers[instance.instanceId] = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          );
          // 启动动画
          _cardAnimationControllers[instance.instanceId]?.forward();
          setState(() {});
          // 移除原有的弃牌动画，改为扫描带消失
          Future.delayed(const Duration(milliseconds: 820), () {
            _discardingCards.remove(instance.instanceId);
            // 释放动画控制器
            _cardAnimationControllers[instance.instanceId]?.dispose();
            _cardAnimationControllers.remove(instance.instanceId);
            setState(() {});
          });
        }
      }
      discardPile.addAll(hand.sublist(1));
      hand.clear();
      hand.add(instanceToKeep);
    } else if (hand.length == 1) {
      // 如果只有1张牌，直接保留
    } else {
      // 如果没有手牌，跳过弃牌阶段
    }

    // 关键区域：林职业被动【冗余利用】—— 弃牌获得格挡
    if (characterData.characterClass == CharacterClass.lin && totalDiscarded > 0) {
      int bonusBlock = totalDiscarded * 2;
      player.block += bonusBlock;
      anim.showBlockGain(player, bonusBlock);
      _showStatusTip("【冗余利用】处理 $totalDiscarded 条冗余数据，防火墙 +$bonusBlock", const Color(0xFFC3A6FF));
      
      // 触发林落叶特效
      final ctx = context;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null) {
        final center = box.size.center(Offset.zero);
        anim.playRoleEffect(CharacterClass.lin, center);
      }
      
      // 等待特效展示
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    if (characterData.characterClass == CharacterClass.yanxin && energy > 0) {
      final candidates = activePrograms.where((m) => m.hp > 0).toList();
      if (candidates.isNotEmpty) {
        final rng = Random();
        for (int i = 0; i < energy; i++) {
          final target = candidates[rng.nextInt(candidates.length)];
          target.fire += 1;
        }
        setState(() {});
      }
    }
    // 弃牌阶段结束后进入系统响应周期
    startSystemResponse();
  }

  // 关键区域：胜负判定
  void checkBattleResult() {
    if (gamePhase == GamePhase.gameOver || _resultScheduling) return;
    if (player.hp <= 0) {
      isVictory = false;
      _scheduleResultOverlay();
      return;
    }
    if (activePrograms.isNotEmpty && activePrograms.every((m) => m.hp <= 0)) {
      isVictory = true;
      if (!_victoryRecorded && widget.levelId != null) {
        GameProgress.markDefeated(widget.levelId!);
        GameStatistics.totalBattlesWon++; // 关键区域：记录赢得的战斗
        _victoryRecorded = true;
        // 关键区域：Boss战胜利时随机决定奖励类型（神圣或恶魔）
        if (GameProgress.isCurrentNationFinished()) {
          _isHolyReward = Random().nextBool();
        }
      }
      _scheduleResultOverlay();
    }
  }
  void _scheduleResultOverlay() {
    _resultScheduling = true;
    _interactionLocked = true;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 800), () {
      gamePhase = GamePhase.gameOver;
      _interactionLocked = false;
      _resultScheduling = false;
      setState(() {});
    });
  }

  /// 手动选择保留的牌（供UI调用）
  void selectCardToKeep(CardInstance instance) async {
    if (gamePhase != GamePhase.discardPhase) return;

    // 将选中的牌保留，其他牌弃掉
    final discardInstances = <CardInstance>[];
    for (final inst in hand) {
      if (inst != instance) {
        discardInstances.add(inst);
      }
    }

    // 对所有要弃掉的卡牌播放动画
    for (final inst in discardInstances) {
      final idx = hand.indexOf(inst);
      if (idx >= 0) {
        final key = _cardKeys[idx];
        final ctx = key?.currentContext;
        final box = ctx?.findRenderObject() as RenderBox?;
        final start = box?.localToGlobal(const Offset(36, 48));
        final dctx = _discardPileKey.currentContext;
        final dbox = dctx?.findRenderObject() as RenderBox?;
        final end = dbox?.localToGlobal(const Offset(50, 30));
        if (start != null && end != null) {
          _discardingCards.add(inst.instanceId);
          // 创建动画控制器
          _cardAnimationControllers[inst.instanceId] = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          );
          // 启动动画
          _cardAnimationControllers[inst.instanceId]?.forward();
          setState(() {});
          // 移除弃牌动画
          Future.delayed(const Duration(milliseconds: 820), () {
            _discardingCards.remove(inst.instanceId);
            discardPile.add(inst);
            // 释放动画控制器
            _cardAnimationControllers[inst.instanceId]?.dispose();
            _cardAnimationControllers.remove(inst.instanceId);
            setState(() {});
          });
        }
      }
    }

    // 清空手牌，只保留选中的卡牌
    hand.clear();
    hand.add(instance);

    // 完成弃牌阶段，传入弃牌数量以触发被动
    await completeDiscardPhase(discardedCount: discardInstances.length);
  }

  /// =====================
  /// UI
  /// =====================

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

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
        body: AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              // 定义当前主题色（基于脑机、职业状态或默认值）
              final themeColor = _getThemeColor();

              return Stack(
                children: [
                  // 关键区域：全域背景美化 - 动态扫描线与网格
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: _BattleBackground(
                      pulses: anim.gridPulses,
                      gridColor: anim.roleEffects.any((e) => e.role == CharacterClass.xueye) 
                          ? const Color(0xFFFF4D4D) 
                          : themeColor,
                    )),
                  ),
                  if (characterData.characterClass == CharacterClass.langchao)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: CyberWaveIdlePainter(repaint: _waveCtrl),
                          ),
                        ),
                      ),
                    ),
                  if (anim.fireOverlayActive)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: CyberFireOverlayPainter(anim.fireOverlayStart!),
                          ),
                        ),
                      ),
                    ),
                  // 关键区域：角色专属特效绘制层（作用于背景之上，UI之下）
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: CyberRoleEffectPainter(anim.roleEffects),
                        ),
                      ),
                    ),
                  ),
                  if (_chipBannerActive && _chipName != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _chipDeployCtrl,
                          builder: (context, _) {
                            final t = Curves.easeOut.transform(_chipDeployCtrl.value.clamp(0.0, 1.0));
                            final col = themeColor;
                            return Opacity(
                              opacity: (t < 0.8 ? t : 1.0 - (t - 0.8) / 0.2).clamp(0.0, 1.0),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: col.withValues(alpha: 0.7)),
                                    boxShadow: [BoxShadow(color: col.withValues(alpha: 0.25), blurRadius: 12)],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.memory, color: col, size: 18),
                                      const SizedBox(width: 10),
                                      Text("${_chipName} 脑机 接入", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
              // 根据屏幕方向选择不同布局
              isLandscape ? _landscapeLayout(themeColor) : _portraitLayout(themeColor),
              // 手牌预览判定区
              _cardPreviewZone(themeColor),
              // 放大预览悬浮窗
              _magnifiedCardPreview(themeColor),
              // 低生命值屏幕红光
              if ((player.hp / player.maxHp.clamp(1, 999999)) < 0.3)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _hpPulseCtrl,
                      builder: (context, _) {
                        final v = _hpPulseCtrl.value;
                        final a = (0.35 * (0.25 + 0.75 * sin(v * pi))).clamp(0.0, 0.6);
                        return CustomPaint(painter: CyberScreenGlowPainter(alpha: a));
                      },
                    ),
                  ),
                ),
                  // 弃牌阶段：显示卡牌选择覆盖层
                  if (gamePhase == GamePhase.discardPhase && isDiscardPhase)
                    _bottomDiscardOverlay(themeColor),
                  // 同步阶段：显示进入弃牌按钮
                  if (gamePhase == GamePhase.syncPhase &&
                      hasDrawnCards &&
                      !isDiscardPhase)
                    _bottomDiscardOverlay(themeColor),
                  _attackGroup(AttackEffectType.laser),
                  _attackGroup(AttackEffectType.slash),
                  _attackGroup(AttackEffectType.explosion),
                  _attackGroup(AttackEffectType.inject),
                  _attackGroup(AttackEffectType.impact),
                  ...anim.motions.map(_cardMotionWidget),
                  ...anim.gamePopups.map((p) => GamePopupWidget(key: ValueKey(p.id), popup: p)),
                  ...anim.shieldBreaks.map(_shieldBreakEffect),
                  if (anim.hpDamageFlashActive)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: Colors.red.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  if (_activeBuffName != null)
                    Positioned(
                      bottom: 125,
                      left: 20,
                      right: 20,
                      child: _buffInfoPanel(themeColor),
                    ),
                  if (_interactionLocked)
                    Positioned.fill(
                      child: AbsorbPointer(
                        absorbing: true,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  if (anim.isScreenOverloaded) _screenOverloadOverlay(),
                  if (gamePhase == GamePhase.gameOver) _resultOverlay(themeColor),
                  if (_statusTip != null) _statusTipWidget(),
                ],
              );
            },
          ),
        ),
      );
    }

  // 竖屏布局：顶部栏 -> 怪物区域 -> 手牌区域 -> 牌堆区域
  Widget _portraitLayout(Color themeColor) {
    return Stack(
      children: [
        // 内容层
        Column(
          children: [
            _topBar(themeColor), // 顶部状态栏
            _battleField(), // 怪物战斗区域
            Expanded(child: _handArea(themeColor)), // 手牌区域
            const SizedBox(height: 60), // 给牌堆留出空间
          ],
        ),
        // 浮动牌堆层 - 左下角：抽牌堆
        Positioned(
          left: 16,
          bottom: 16,
          child: KeyedSubtree(
            key: _drawPileKey,
            child: _pileWidget(
              Icons.style,
              drawPile.length,
              themeColor,
              isDrawPile: true,
              onTap: () => _showCardListDialog("抽牌堆", drawPile, themeColor),
            ),
          ),
        ),
        // 浮动牌堆层 - 右下角：弃牌堆
        Positioned(
          right: 16,
          bottom: 16,
          child: KeyedSubtree(
            key: _discardPileKey,
            child: _pileWidget(
              Icons.auto_delete,
              discardPile.length,
              const Color(0xFFFF5A5A),
              isDrawPile: false,
              onTap: () => _showCardListDialog("弃牌堆", discardPile, const Color(0xFFFF5A5A)),
            ),
          ),
        ),
      ],
    );
  }

  // 横屏布局：左侧怪物区域 -> 中间手牌区域 -> 右侧顶部状态栏和牌堆区域
  Widget _landscapeLayout(Color themeColor) {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(child: _battleField()), // 怪物战斗区域
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _topBar(themeColor),
                  Expanded(child: _handArea(themeColor)),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
        // 牌堆 (横屏模式也使用浮动位置)
        Positioned(
          left: 16,
          bottom: 16,
          child: _pileWidget(
            Icons.style,
            drawPile.length,
            themeColor,
            isDrawPile: true,
            onTap: () => _showCardListDialog("抽牌堆", drawPile, themeColor),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: _pileWidget(
            Icons.auto_delete,
            discardPile.length,
            const Color(0xFFFF5A5A),
            isDrawPile: false,
            onTap: () => _showCardListDialog("弃牌堆", discardPile, const Color(0xFFFF5A5A)),
          ),
        ),
      ],
    );
  }

  // 游戏状态提示组件
  Widget _statusTipWidget() {
    final themeColor = _getThemeColor();
    final color = _statusTipColor ?? themeColor;
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            _statusTip!,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  // 关键区域：顶部HUD（SafeArea避免状态栏遮挡）
  Widget _cyberIntentBar({
    required String text,
    IconData? icon,
    String? value,
    required double width,
    double height = 18,
    required Color color,
    required double s,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF05060A),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(10),
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(3),
          bottomLeft: Radius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // 动态背景斜纹
            Positioned.fill(
              child: CustomPaint(
                painter: CyberHpBarBackgroundPainter(color: color.withValues(alpha: 0.08)),
              ),
            ),
            // 装饰性渐变背景
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ),
            // 左侧装饰块
            Container(
              width: 3 * s,
              height: height,
              color: color,
            ),
            // 内容区域
            Padding(
              padding: EdgeInsets.only(left: 6 * s, right: 6 * s),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: (10 * s).clamp(8, 11),
                      color: color.withValues(alpha: 0.9),
                    ),
                    SizedBox(width: 4 * s),
                  ],
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: (8.5 * s).clamp(7.5, 9.5),
                        fontWeight: FontWeight.w900,
                        color: color.withValues(alpha: 0.95),
                        fontFamily: 'monospace',
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 2),
                          Shadow(color: color.withValues(alpha: 0.3), blurRadius: 4),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (value != null) ...[
                    SizedBox(width: 4 * s),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: (10 * s).clamp(9, 11),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(color: color, blurRadius: 6),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cyberHpBar({
    required int current,
    required int maxHp,
    required double width,
    double height = 24,
    Color? color,
    String label = "SYS.UNIT",
    IconData? suiteIcon,
    bool isMonster = false,
  }) {
    final barColor = color ?? _getThemeColor();
    final double percent = (current / maxHp.clamp(1, 999999)).clamp(0.0, 1.0);
    final bool isLowHp = percent < 0.3;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // 背景容器
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF05060A),
            borderRadius: isMonster
                ? const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(12),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomRight: Radius.circular(12),
                  ),
            border: Border.all(
              color: isLowHp ? Colors.red.withValues(alpha: 0.6) : barColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isLowHp ? Colors.red : barColor).withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: isMonster
                ? const BorderRadius.only(
                    topRight: Radius.circular(3),
                    bottomLeft: Radius.circular(10),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    bottomRight: Radius.circular(10),
                  ),
            child: Stack(
              children: [
                // 动态背景斜纹
                Positioned.fill(
                  child: CustomPaint(
                    painter: CyberHpBarBackgroundPainter(color: barColor.withValues(alpha: 0.08)),
                  ),
                ),
                // 装饰性分段网格
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                          (width / 12).toInt(),
                          (i) => Container(
                                width: 1.5,
                                color: Colors.black,
                              )),
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  duration: isMonster ? Duration.zero : const Duration(milliseconds: 800),
                  curve: Curves.easeOutExpo,
                  tween: Tween(begin: 0, end: percent),
                  builder: (context, value, child) {
                    if (value <= 0) return const SizedBox.shrink();
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              isLowHp ? Colors.red.withValues(alpha: 0.4) : barColor.withValues(alpha: 0.4),
                              isLowHp ? Colors.red.withValues(alpha: 0.8) : barColor.withValues(alpha: 0.8),
                              isLowHp ? Colors.red : barColor,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // 右侧发光线 (赛博边缘)
                            Positioned(
                              top: 0,
                              right: 0,
                              bottom: 0,
                              width: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isLowHp ? Colors.red : barColor),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // 低生命值警告呼吸效果
        if (isLowHp)
          AnimatedBuilder(
            animation: _hpPulseCtrl,
            builder: (context, _) {
              final val = _hpPulseCtrl.value;
              final a = (0.5 * (0.3 + 0.7 * sin(val * pi))).clamp(0.0, 1.0);
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: isMonster
                      ? const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomLeft: Radius.circular(12),
                        )
                      : const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomRight: Radius.circular(12),
                        ),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: a),
                    width: 2,
                  ),
                ),
              );
            },
          ),
        // 数值和标签
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      "$current / $maxHp",
                      style: TextStyle(
                        color: isLowHp ? Colors.red : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 0.8,
                        shadows: [
                          const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                          Shadow(color: (isLowHp ? Colors.red : barColor).withValues(alpha: 0.8), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar(Color themeColor) {
    return SafeArea(
      top: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF101722).withValues(alpha: 0.95),
              const Color(0xFF0A0F16).withValues(alpha: 0.85),
            ],
          ),
          border: Border(
              bottom: BorderSide(
              color: themeColor.withValues(alpha: 0.4),
              width: 1.6,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _chipDeployCtrl,
                builder: (context, _) {
                  return CustomPaint(painter: CyberTopBarGridPainter(color: themeColor, progress: _chipDeployCtrl.value));
                },
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // 元数据标签
            Row(
              children: [
                Icon(Icons.link, size: 10, color: themeColor.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  "INTEGRITY_LINK",
                  style: TextStyle(
                    color: themeColor.withValues(alpha: 0.6),
                    fontSize: 8,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeColor.withValues(alpha: 0.15), themeColor.withValues(alpha: 0.05)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomRight: Radius.circular(6),
                    ),
                    border: Border.all(color: themeColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: themeColor, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "当前位置: ${widget.levelId ?? 'UNKNOWN'}",
                        style: TextStyle(
                          color: themeColor.withValues(alpha: 0.9),
                          fontSize: 8,
                          letterSpacing: 0.8,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 8,
                        color: themeColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "执行回合数: $turnCount",
                        style: TextStyle(
                          color: turnCount >= 10 ? Colors.orangeAccent : themeColor.withValues(alpha: 0.9),
                          fontSize: 8,
                          letterSpacing: 0.8,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          shadows: turnCount >= 10 ? [
                            Shadow(color: Colors.orangeAccent.withValues(alpha: 0.5), blurRadius: 4),
                          ] : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 关键区域：金币/信用点显示
                      Container(
                        width: 1,
                        height: 8,
                        color: themeColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.monetization_on, size: 10, color: Color(0xFFFFD700)),
                      const SizedBox(width: 4),
                      Text(
                        "${GameState.playerGold}",
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 9,
                          letterSpacing: 0.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左侧：地图按钮 + HP进度条 + 护盾值
                Row(
                  children: [
                    // 地图按钮
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          createHoloRoute(const MapScreen(
                            canReturnToGame: true,
                            canSelect: false,
                          )),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          border: Border.all(
                            color: themeColor.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.map,
                          size: 16,
                          color: themeColor,
                        ),
                      ),
                    ),
                    // HP 区域
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: anim.glitching.contains(player) ? 1.06 : 1.0,
                          child: _cyberHpBar(
                            current: player.hp,
                            maxHp: player.maxHp,
                            width: 160,
                            height: 24,
                            label: "",
                            color: themeColor,
                            suiteIcon: brainChipDatabase[GameState.selectedBrainChipId]?.suiteIconCode != null 
                                ? IconData(brainChipDatabase[GameState.selectedBrainChipId]!.suiteIconCode, fontFamily: 'MaterialIcons') 
                                : null,
                          ),
                        ),
                        if (anim.lastPlayerDamage != null)
                          Positioned(
                            right: -18,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (_, t, child) {
                                final opacity = t < 0.75 ? 1.0 : 1.0 - (t - 0.75) / 0.25;
                                final scale = t < 0.15 ? 0.7 + t * 2.2 : 1.2 - (t - 0.15) * 0.2;
                                return Opacity(
                                  opacity: opacity.clamp(0.0, 1.0),
                                  child: Transform.scale(
                                    scale: scale.clamp(0.0, 1.4),
                                    child: Text(
                                      "-${anim.lastPlayerDamage}",
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.redAccent,
                                        fontFamily: 'monospace',
                                        shadows: [
                                          Shadow(color: Colors.black, blurRadius: 4),
                                          Shadow(color: Colors.redAccent, blurRadius: 12),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // 防火墙 FWL 容器
                    TweenAnimationBuilder<double>(
                      key: ValueKey("block_${player.block}"),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      tween: Tween(begin: 1.2, end: 1.0),
                      builder: (context, scale, child) {
                        final bool hasBlock = player.block > 0;
                        final Color blockColor = hasBlock
                            ? themeColor
                            : (themeColor.withValues(alpha: 0.4));
                        
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF0A0F16).withValues(alpha: 0.95),
                                  const Color(0xFF101722).withValues(alpha: 0.95),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(2),
                                bottomRight: Radius.circular(10),
                              ),
                              border: Border.all(
                                color: blockColor.withValues(alpha: hasBlock ? 0.6 : 0.2),
                                width: hasBlock ? 1.2 : 0.8,
                              ),
                              boxShadow: [
                                if (hasBlock)
                                  BoxShadow(
                                    color: blockColor.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Row(
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(milliseconds: 1500),
                                      builder: (context, val, child) {
                                        return Opacity(
                                          opacity: hasBlock ? (0.8 + 0.2 * sin(val * pi)) : 0.4,
                                          child: Icon(
                                            hasBlock ? Icons.shield : Icons.shield_outlined,
                                            size: 11,
                                            color: blockColor,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "FWL·护盾",
                                      style: TextStyle(
                                        color: blockColor.withValues(alpha: 0.6),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${player.block}",
                                      style: TextStyle(
                                        color: hasBlock ? Colors.white : blockColor.withValues(alpha: 0.5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                        shadows: [
                                          if (hasBlock)
                                            Shadow(color: blockColor.withValues(alpha: 0.5), blurRadius: 6),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // 右侧：退出按钮
                GestureDetector(
                  onTap: () async {
                    final shouldExit = await showCyberConfirmExit(context);
                    if (shouldExit && context.mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0A0A).withValues(alpha: 0.8),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomRight: Radius.circular(12),
                      ),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.power_settings_new,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _statusEffectsBar(player),
            const SizedBox(height: 6),
            _brainChipBadge(),
          ],
        ),
      ]),
    ));
  }

  /// 获取游戏阶段对应的颜色

  // 关键区域：底部“进入弃牌”覆盖层
  Widget _bottomDiscardOverlay(Color themeColor) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: startDiscardPhase,
          child: Container(
            width: 140,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A0F16).withValues(alpha: 0.95),
                  const Color(0xFF1A1F26).withValues(alpha: 0.95),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border.all(color: themeColor.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // 装饰性微光
                Positioned(
                  top: -15,
                  left: -15,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 2000),
                        builder: (context, val, child) {
                          return Opacity(
                            opacity: 0.7 + 0.3 * sin(val * pi),
                            child: Icon(Icons.sync, color: themeColor, size: 18),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "结束阶段",
                        style: TextStyle(
                          color: themeColor.withValues(alpha: 0.95),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                          shadows: [
                            Shadow(color: themeColor.withValues(alpha: 0.5), blurRadius: 4),
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
      ),
    );
  }

  Widget _brainChipBadge() {
    final chipId = GameState.selectedBrainChipId;
    if (chipId == null) return const SizedBox.shrink();
    final chip = brainChipDatabase[chipId] ?? brainChipPool.first;
    final col = Color(chip.themeColor);
    
    return GestureDetector(
      onTap: () {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: "BRAIN_CHIP_INFO",
          barrierColor: Colors.black.withValues(alpha: 0.85),
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (ctx, a1, a2) {
            return Center(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Material(
                  color: Colors.transparent,  
                  child: Container(
                    width: 340,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [col.withValues(alpha: 0.5), col.withValues(alpha: 0.1)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0F16).withValues(alpha: 0.98),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        children: [
                          // 背景装饰装饰线
                          Positioned(
                            top: 0, right: 40,
                            child: Container(width: 2, height: 20, color: col.withValues(alpha: 0.3)),
                          ),
                          Positioned(
                            top: 15, right: 0,
                            child: Container(width: 30, height: 2, color: col.withValues(alpha: 0.3)),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: col.withValues(alpha: 0.1),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          bottomRight: Radius.circular(12),
                                        ),
                                        border: Border.all(color: col.withValues(alpha: 0.3)),
                                        boxShadow: [
                                          BoxShadow(color: col.withValues(alpha: 0.1), blurRadius: 10),
                                        ],
                                      ),
                                      child: Icon(IconData(chip.suiteIconCode, fontFamily: 'MaterialIcons'), color: col, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chip.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                chip.suiteName,
                                                style: TextStyle(
                                                  color: col.withValues(alpha: 0.8),
                                                  fontSize: 11,
                                                  letterSpacing: 1,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 4, height: 4,
                                                decoration: BoxDecoration(shape: BoxShape.circle, color: col.withValues(alpha: 0.5)),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "VER 2.0.${chip.level}",
                                                style: TextStyle(
                                                  color: col.withValues(alpha: 0.6),
                                                  fontSize: 10,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // 效果区域
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: col.withValues(alpha: 0.05),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      bottomRight: Radius.circular(15),
                                    ),
                                    border: Border.all(color: col.withValues(alpha: 0.15)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.terminal, color: col, size: 14),
                                          const SizedBox(width: 8),
                                          Text(
                                            "SYSTEM_EFFECT_LOG",
                                            style: TextStyle(
                                              color: col.withValues(alpha: 0.7),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20, thickness: 0.5, color: Colors.white12),
                                      Text(
                                        chip.description,
                                        style: const TextStyle(
                                          color: Color(0xFFE0E6ED),
                                          fontSize: 14,
                                          height: 1.5,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // 装饰性的小元素
                                    Row(
                                      children: List.generate(3, (i) => Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        width: 12, height: 2,
                                        color: col.withValues(alpha: 0.2 + (i * 0.2)),
                                      )),
                                    ),
                                    CyberButton(
                                      label: "关闭",
                                      width: 100,
                                      height: 36,
                                      fontSize: 12,
                                      color: col,
                                      onPressed: () => Navigator.pop(ctx),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [col.withValues(alpha: 0.8), col.withValues(alpha: 0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            bottomRight: Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: col.withValues(alpha: 0.15),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F16).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              bottomRight: Radius.circular(14),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: CyberScanline(color: col.withValues(alpha: 0.1)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: 0.7 + (0.3 * sin(value * pi)),
                          child: Icon(
                            IconData(chip.suiteIconCode, fontFamily: 'MaterialIcons'),
                            size: 16,
                            color: col,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "已接入脑机",
                          style: TextStyle(
                            color: col.withValues(alpha: 0.5),
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          chip.name,
                          style: TextStyle(
                            color: col,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.info_outline_rounded, size: 10, color: col.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  /// 获取游戏阶段对应的文本

  Widget _battleField() {
    return Container(
      height: 220, // 增加高度，从 200 增加到 220，为 Buff 栏预留空间
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
                    runSpacing: 12, // 增加垂直间距
                    children:
                        activePrograms
                            .map((program) => _securityProgramWidget(program))
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
    final themeColor = _getThemeColor();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _playerWidget(player),
        Positioned(
          top: -90,
          left: -10,
          child: _energyCoreWidget(themeColor),
        ),
      ],
    );
  }

  // 基础空闲悬浮/呼吸动画组件
  Widget _idleAnimationWrapper({required Widget child, required bool isMonster, required String id}) {
    return _LoopingIdleWidget(
      isMonster: isMonster,
      id: id,
      child: child,
    );
  }

  Widget _playerWidget(Entity e, {bool isHighlighted = false}) {
    final isGlitching = anim.glitching.contains(e);
    final isProtecting = anim.protecting.contains(e);
    final isBouncing = anim.bouncing.contains(e);

    // 获取当前主题色
    final themeColor = _getThemeColor();

    // 内部构建核心内容，完全不带任何 Key
    Widget buildCore() {
      return Container(
        width: 70,
        height: 85,
        decoration: BoxDecoration(
          color: isHighlighted ? themeColor.withValues(alpha: 0.15) : const Color(0xFF0A0F16),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isHighlighted 
                ? themeColor
                : (isProtecting 
                    ? themeColor 
                    : themeColor.withValues(alpha: 0.4)),
            width: (isProtecting || isHighlighted) ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isProtecting || isHighlighted)
                  ? themeColor.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
              blurRadius: (isProtecting || isHighlighted) ? 15 : 10,
              spreadRadius: (isProtecting || isHighlighted) ? 2 : 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 增加背景装饰
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CustomPaint(
                  painter: CyberCornerPainter(
                    color: (isHighlighted ? themeColor : themeColor.withValues(alpha: 0.2)),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.1.clamp(0.0, 1.0),
                child: CyberScanline(color: themeColor),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _idleAnimationWrapper(
                    id: "player_icon",
                    isMonster: false,
                    child: Icon(
                      characterData.icon,
                      size: 38,
                      color: isHighlighted 
                          ? themeColor
                          : themeColor.withValues(alpha: 0.8),
                      shadows: [
                        Shadow(
                          color: themeColor.withValues(alpha: 0.5),
                          blurRadius: isHighlighted ? 12 : 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    characterData.name,
                    style: TextStyle(
                      color: themeColor.withValues(alpha: 0.7),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (isProtecting)
              // 防御脉冲外圈
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.3),
                duration: const Duration(milliseconds: 500),
                builder: (_, val, __) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: themeColor.withValues(alpha: (1.0 - (val - 1.0) * 3).clamp(0.0, 1.0)),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final box = TweenAnimationBuilder<double>(
      key: ValueKey("player_anim_builder_${e.id}_${isGlitching}_${isProtecting}_$isBouncing"),
      duration: Duration(milliseconds: isGlitching ? 400 : (isBouncing ? 450 : 200)),
      tween: Tween(begin: 0, end: 1),
      curve: isBouncing ? Curves.easeOutBack : Curves.linear,
      builder: (context, t, child) {
        double dx = 0, dy = 0;
        double scale = 1.0;
        double rotation = 0.0;

        if (isGlitching) {
          dx = sin(t * 8 * pi) * 6 * (1 - t);
          rotation = sin(t * 4 * pi) * 0.03 * (1 - t);
        }

        if (isBouncing) {
          dy = -sin(t * pi) * 10; 
          scale = 1.0 + 0.05 * sin(t * pi);
        }

        Widget content = buildCore();

        if (isGlitching) {
          content = ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.white.withValues(alpha: (0.6 * (1 - t)).clamp(0.0, 1.0)),
              BlendMode.srcATop,
            ),
            child: content,
          );
        }

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: content,
            ),
          ),
        );
      },
    );

    // 将 GlobalKey 提升到最顶层容器，确保其唯一性
    return RepaintBoundary(
      child: AnimatedOpacity(
        key: e.key,
        opacity: 1.0,
        duration: const Duration(milliseconds: 100),
        child: box,
      ),
    );
  }

  Widget _buildSciFiButton({
    required String text,
    required VoidCallback onTap,
    required Color color,
    IconData? icon,
    double? width,
    String? heroTag,
  }) {
    Widget button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 54, // 固定高度更显专业
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F16).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
            // 内发光效果
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 2,
              spreadRadius: -1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 背景渐变
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.1),
                      Colors.transparent,
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    bottomRight: Radius.circular(15),
                  ),
                ),
              ),
            ),
            // 内部动态扫描线
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  bottomRight: Radius.circular(15),
                ),
                child: CyberScanline(color: color.withValues(alpha: 0.25)),
              ),
            ),
            // 装饰边角
            Positioned.fill(
              child: CustomPaint(
                painter: CyberCornerPainter(color: color.withValues(alpha: 0.6)),
              ),
            ),
            // 侧边装饰条
            Positioned(
              left: 0,
              top: 10,
              bottom: 10,
              width: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                  boxShadow: [
                    BoxShadow(color: color, blurRadius: 4),
                  ],
                ),
              ),
            ),
            // 按钮内容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      fontFamily: 'monospace',
                      shadows: [
                        Shadow(color: color.withValues(alpha: 0.8), blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          child: button,
        ),
      );
    }
    return button;
  }

  // 关键区域：结果层（胜利/失败）
  Widget _resultOverlay(Color themeColor) {
    final color = isVictory ? themeColor : const Color(0xFFFF4444);
    
    return Positioned.fill(
      child: Stack(
        children: [
          // 1. 全局背景模糊
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
          
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              builder: (_, t, __) {
                final scale = 0.85 + 0.15 * t;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isVictory) _victoryParticles(t, themeColor),
                    
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 400, // 增加宽度以适应两个 160 宽度的按钮，原为 360
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0F16).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            const BoxShadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 装饰边角
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: CyberCornerPainter(color: color.withValues(alpha: 0.6)),
                                ),
                              ),
                            ),
                            
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 标题区域
                                if (isVictory)
                                  _victoryTitle(t, themeColor)
                                else
                                  Column(
                                    children: [
                                      Text(
                                        'CRITICAL_FAILURE',
                                        style: TextStyle(
                                          color: color.withValues(alpha: 0.5),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 3,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '渗透任务失败：接入被强行中断',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                          shadows: [
                                            Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                
                                const SizedBox(height: 24),
                                _gameStatisticsWidget(themeColor),
                                const SizedBox(height: 28),
                                
                                // Boss 奖励选择区域
                                if (isVictory && GameProgress.isCurrentNationFinished() && !_bossRewardSelected)
                                  _bossRewardSelectionWidget(themeColor)
                                else
                                // 按钮区域
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (isVictory) ...[
                                      _overlayButton(
                                        Icons.map,
                                        GameProgress.isCurrentNationFinished() ? "同步完成" : "拓扑网络",
                                        () {
                                          // 胜利后，标记当前关卡已击败
                                          if (widget.levelId != null) {
                                            GameProgress.markDefeated(widget.levelId!);
                                          }
                                          
                                          // 如果是通关（整个国家完成），则结算数据到累计统计
                                          if (GameProgress.isCurrentNationFinished()) {
                                            GameStatistics.commitRunStats();
                                          }
                                          
                                          Navigator.pushReplacement(
                                            context,
                                            createHoloRoute(
                                              const MapScreen(
                                                canReturnToGame: true,
                                                canSelect: true,
                                              ),
                                            ),
                                          );
                                        },
                                        color: themeColor,
                                        heroTag: 'main_action_button',
                                      ),
                                    ] else ...[
                                      _overlayButton(
                                        Icons.refresh,
                                        "重载系统",
                                        () {
                                          // 关键区域：记录失败前的数据到累计统计
                                          GameStatistics.commitRunStats();
                                          
                                          GameProgress.resetRunData();
                                          GameState.reset();
                                          GameStatistics.reset();
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            createHoloRoute(const StartScreen()),
                                            (route) => false,
                                          );
                                        },
                                        color: const Color(0xFFFF6A6A),
                                        heroTag: 'main_action_button',
                                      ),
                                    ],
                                  ],
                                ),
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
        ],
      ),
    );
  }

  // 屏幕过载分层效果（颜色偏移与扫描线叠加）
  Widget _screenOverloadOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AnimDurations.screenOverload,
          builder: (_, t, __) {
            final alpha = (1.0 - t).clamp(0.0, 0.5);
            return Stack(
              children: [
                Container(color: Colors.red.withValues(alpha: 0.03 * alpha)),
                Positioned.fill(
                  child: CustomPaint(painter: CyberScanlineJitterPainter(strength: 2.0 * (1.0 - t))),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  // 关键区域：Boss 奖励选择
  Widget _bossRewardSelectionWidget(Color themeColor) {
    return Column(
      children: [
        const Text(
          "--- 检测到核心溢出：请选择奖励 ---",
          style: TextStyle(
            color: Colors.amber, 
            fontSize: 12, 
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _rewardOption(
              icon: Icons.memory,
              title: "获取随机脑机",
              desc: "销毁旧脑机，接入新协议\n(系统稳定性下降: -2 Max HP)",
              color: themeColor,
              onTap: () => _handleBrainChipReward(),
            ),
            const SizedBox(width: 20),
            if (_isHolyReward)
              _rewardOption(
                icon: Icons.auto_awesome,
                title: "获取神圣牌",
                desc: "接受来自高维的圣洁祝福\n(Lv ? 圣洁指令)",
                color: const Color(0xFFFFD700),
                onTap: () => _handleHolyCardReward(),
              )
            else
              _rewardOption(
                icon: Icons.pest_control_rodent_rounded,
                title: "获取恶魔牌",
                desc: "一张拥有毁天灭地力量的卡牌\n(Lv ? 禁忌指令)",
                color: const Color(0xFF9D00FF),
                onTap: () => _handleDemonCardReward(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _rewardOption({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 120,
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: const Color(0xFF05060A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title, 
              style: TextStyle(
                color: color, 
                fontWeight: FontWeight.bold, 
                fontSize: 13,
                fontFamily: 'monospace',
              )
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withValues(alpha: 0.7), 
                fontSize: 9,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBrainChipReward() {
    final random = Random();
    // 排除当前已有的脑机
    final availableChips = brainChipPool.where((c) => c.id != GameState.selectedBrainChipId).toList();
    if (availableChips.isEmpty) return;
    final newChip = availableChips[random.nextInt(availableChips.length)];
    // 确保颜色不为黑色，避免与背景重叠
    Color chipColor = Color(newChip.themeColor);
    if (chipColor.computeLuminance() < 0.05) {
      chipColor = Colors.blueAccent; // 默认为蓝色
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "BRAIN_CHIP_CONFIRM",
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: 0.9 + 0.1 * a1.value,
          child: Opacity(opacity: a1.value, child: child),
        );
      },
      pageBuilder: (ctx, a1, a2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. 外部装饰边框
                Positioned(
                  top: -10, left: -10, right: -10, bottom: -10,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: chipColor.withValues(alpha: 0.1), width: 1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
                // 2. 主容器
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: const Color(0xFF05060A),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border.all(color: chipColor.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: chipColor.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 5),
                      BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 20),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomRight: Radius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        // 背景网格装饰
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.15,
                            child: CustomPaint(
                              painter: CyberGridPainter(
                                color: chipColor,
                                opacity: 0.1,
                                spacing: 20.0,
                                showChars: false,
                              ),
                            ),
                          ),
                        ),
                        // 扫描线
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CyberScanline(color: chipColor.withValues(alpha: 0.05)),
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 头部：系统状态标签
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _metaLabel("SYSTEM_INTEGRATION", chipColor),
                                  _metaLabel("ID: ${newChip.id.toUpperCase()}", chipColor.withValues(alpha: 0.5)),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 警告区域：架构冲突
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  border: Border(
                                    left: BorderSide(color: Colors.redAccent, width: 3),
                                    right: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3), width: 1),
                                  ),
                                  gradient: LinearGradient(
                                    colors: [Colors.redAccent.withValues(alpha: 0.15), Colors.transparent],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          "CRITICAL_SYSTEM_CONFLICT",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'monospace',
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "检测到架构冲突：最大生命值将下降 2 点",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),

                              // 脑机核心图标与信息
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 背景发光
                                  Container(
                                    width: 100, height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: chipColor.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 10),
                                      ],
                                    ),
                                  ),
                                  // 图标外框
                                  Container(
                                    width: 86, height: 86,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: chipColor.withValues(alpha: 0.3), width: 1),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(2),
                                        bottomRight: Radius.circular(20),
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: chipColor.withValues(alpha: 0.05),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(2),
                                          bottomRight: Radius.circular(16),
                                        ),
                                        border: Border.all(color: chipColor.withValues(alpha: 0.5), width: 1.5),
                                      ),
                                      child: Icon(
                                        IconData(newChip.suiteIconCode, fontFamily: 'MaterialIcons'),
                                        color: chipColor,
                                        size: 44,
                                        shadows: [Shadow(color: chipColor.withValues(alpha: 0.5), blurRadius: 15)],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                              
                              Text(
                                newChip.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: chipColor.withValues(alpha: 0.1),
                                      border: Border.all(color: chipColor.withValues(alpha: 0.5), width: 1),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      "Lv.${newChip.level}",
                                      style: TextStyle(
                                        color: chipColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "MOD_SPECIFICATION_v4.2",
                                    style: TextStyle(
                                      color: chipColor.withValues(alpha: 0.4),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: chipColor.withValues(alpha: 0.03),
                                  border: Border.all(color: chipColor.withValues(alpha: 0.1), width: 0.5),
                                ),
                                child: Text(
                                  newChip.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                    height: 1.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // 交互按钮
                              Row(
                                children: [
                                  Expanded(
                                    child: _dialogButton(
                                      label: "放弃接入",
                                      color: Colors.grey.shade700,
                                      onTap: () async {
                                        final confirm = await showCyberConfirmExit(
                                          ctx,
                                          color: Colors.redAccent,
                                          title: "确认放弃脑机接入？",
                                          content: "放弃后该奖励将永久失效",
                                          cancelLabel: "取消",
                                          confirmLabel: "确认放弃",
                                        );

                                        if (confirm == true) {
                                          // 不再关闭整个对话框，只更新状态让奖励选择消失
                                          // Navigator.pop(ctx); 
                                          setState(() {
                                            _bossRewardSelected = true;
                                            _statusTip = "放弃了新的脑机接入";
                                            _statusTipColor = Colors.grey;
                                          });
                                          Navigator.pop(ctx); // 关闭 showGeneralDialog 的那个 ctx
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _dialogButton(
                                      label: "安装模块",
                                      color: chipColor,
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        setState(() {
                                          GameState.playerMaxHp = (GameState.playerMaxHp - 2).clamp(1, 999);
                                          GameState.playerHp = min(GameState.playerHp, GameState.playerMaxHp);
                                          GameState.selectedBrainChipId = newChip.id;
                                          GameState.applyBrainChipInstantEffects(newChip.id);
                                          
                                          // 实时更新当前战斗中的玩家属性
                                          player.maxHp = GameState.playerMaxHp;
                                          player.hp = min(player.hp, player.maxHp);
                                          player.strength = GameState.permanentStrength;
                                          player.block = GameState.permanentBlock;
                                          
                                          _bossRewardSelected = true;
                                          _statusTip = "脑机已更换，最大生命值 -2";
                                          _statusTipColor = Colors.orangeAccent;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // 角落装饰
                        Positioned(
                          top: 0, left: 0,
                          child: CustomPaint(
                            size: const Size(40, 40),
                            painter: CyberCornerPainter(
                              color: chipColor.withValues(alpha: 0.8),
                              cornerSize: 15,
                              strokeWidth: 1.5,
                            ),
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
      },
    );
  }

  void _handleDemonCardReward() {
    final demonCards = cardDatabase.values.where((c) => c.suite == CardSuite.demon).toList();
    if (demonCards.isEmpty) return;
    final card = demonCards[Random().nextInt(demonCards.length)];

    setState(() {
      GameState.drawPile.add(card.id);
      _bossRewardSelected = true;
      _statusTip = "恶魔指令 [${card.name}] 已注入指令集";
      _statusTipColor = const Color(0xFF9D00FF);
    });
  }

  void _handleHolyCardReward() {
    final holyCards = cardDatabase.values.where((c) => c.suite == CardSuite.holy).toList();
    if (holyCards.isEmpty) return;
    final card = holyCards[Random().nextInt(holyCards.length)];

    setState(() {
      GameState.drawPile.add(card.id);
      _bossRewardSelected = true;
      _statusTip = "神圣指令 [${card.name}] 已注入指令集";
      _statusTipColor = const Color(0xFFFFD700);
    });
  }

  Widget _metaLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _dialogButton({required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36, // 减小高度，使其更修长
        padding: const EdgeInsets.symmetric(horizontal: 20), // 增加左右间距，强化长方形感
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(1),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: 3, bottom: 3,
              child: Container(width: 3, height: 3, color: color.withValues(alpha: 0.5)),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11, // 稍微缩小字号
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlayButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    required Color color,
    String? heroTag,
  }) {
    return _buildSciFiButton(
      heroTag: heroTag,
      text: label,
      onTap: onTap,
      color: color,
      icon: icon,
      width: 160, // 增加宽度防止文本溢出，原为 140
    );
  }

  // 关键区域：胜利页面标题（动态渐变）
  Widget _victoryTitle(double t, Color themeColor) {
    return Column(
      children: [
        Text(
          'DATA_SYNC_COMPLETE',
          style: TextStyle(
            color: themeColor.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            final paint = Paint()
              ..shader = LinearGradient(
                colors: [themeColor, const Color(0xFFE1E9FF), themeColor],
                stops: [0.0, value, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(const Rect.fromLTWH(0, 0, 300, 40));
            
            return Text(
              '核心数据下载完成',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                foreground: paint,
                shadows: [
                  Shadow(color: themeColor.withValues(alpha: 0.3), blurRadius: 10),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 游戏统计信息组件
  Widget _gameStatisticsWidget(Color themeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF05060A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2A4158), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                color: themeColor,
              ),
              const SizedBox(width: 8),
              const Text(
                '本次战斗实时统计 / BATTLE_STATS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _statRow('执行回合数', '${GameStatistics.battleTurns}', const Color(0xFFE1E9FF)),
          _statRow('本局出牌数', '${GameStatistics.battleCardsUsed}', themeColor),
          _statRow('本局造成伤害)', '${GameStatistics.battleDamageDealt}', const Color(0xFFFF6A6A)),
          _statRow('本局护盾拦截', '${GameStatistics.battleDamageBlocked}', const Color(0xFF5AD1FF)),
          _statRow('胜场', '${GameStatistics.totalBattlesWon}', const Color(0xFF44FF44)),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(color: valueColor.withValues(alpha: 0.3), blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  valueColor.withValues(alpha: 0.2),
                  valueColor.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 关键区域：胜利粒子效果（星光）
  // 关键区域：胜利后的粒子飘散效果 - 动态增强版
  Widget _victoryParticles(double t, Color themeColor) {
    // 预设一些更丰富的粒子轨道
    final particles = List.generate(12, (i) {
      final angle = (i * 30) * pi / 180;
      final dist = 0.5 + 0.5 * sin(t * pi + i);
      return Alignment(
        cos(angle) * dist * (0.8 + 0.2 * t),
        sin(angle) * dist * (0.8 + 0.2 * t) - (0.3 * t), // 向上飘动
      );
    });

    return Stack(
      children: particles.map((a) {
        final index = particles.indexOf(a);
        return Align(
          alignment: a,
          child: Opacity(
            opacity: (1.0 - t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: ((0.5 + 0.5 * t) * (index % 2 == 0 ? 1.2 : 0.8)).clamp(0.0, 2.0),
              child: Icon(
                index % 3 == 0 ? Icons.auto_awesome : Icons.star,
                color: index % 2 == 0 ? Colors.amberAccent : themeColor,
                size: 14 + 10 * (1 - t),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _securityProgramWidget(Entity program) {
    double _monsterScale() {
      final n = activePrograms.length;
      double countScale;
      if (n >= 5) countScale = 0.75;
      else if (n >= 4) countScale = 0.82;
      else if (n >= 3) countScale = 0.9;
      else countScale = 1.0;
      double typeScale = 1.0;
      final data = program.id != null ? systemDatabase[program.id!] : null;
      if (data != null) {
        switch (data.type) {
          case SystemType.normal:
            typeScale = 0.92;
            break;
          case SystemType.elite:
            typeScale = 0.86;
            break;
          case SystemType.boss:
            typeScale = 1.0;
            break;
        }
      }
      return (countScale * typeScale).clamp(0.7, 1.0);
    }
    final s = _monsterScale().clamp(0.7, 1.0);
    return DragTarget<CardInstance>(
      onWillAccept: (instance) {
        final card = instance?.data;
        if (card == null) return false;
        
        // 根据卡牌定义的 target 来决定是否接受
        final accept = (card.target == CardTarget.enemy || card.target == CardTarget.all) && program.hp > 0;
        
        if (accept) {
          highlightedTarget = program;
          setState(() {});
        }
        return accept;
      },
      onAccept: (instance) {
        useCard(instance, program);
        // 添加卡牌使用时的粒子效果
        if (instance.data != null) {
          _showCardUseEffect(instance.data!, program);
        }
      },
      onLeave: (_) {
        highlightedTarget = null;
        setState(() {});
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = highlightedTarget == program;
        final isBeingDragged = candidateData.isNotEmpty;
        final isDead = program.hp <= 0;

        final isGlitching = anim.glitching.contains(program);
        final isProtecting = anim.protecting.contains(program);
        final isBouncing = anim.bouncing.contains(program);

        // 获取当前主题色
        final themeColor = _getThemeColor();

        // 内部构建核心内容，完全不带 Key
        Widget buildCore() {
          final coreColor = isDead 
              ? const Color(0xFFFF4444) 
              : (isHighlighted ? themeColor : const Color(0xFF2A4158));

          return Container(
            width: 90 * s, 
            height: 110 * s,
            decoration: BoxDecoration(
              color:
                  isDead
                      ? Colors.grey.shade900.withValues(alpha: 0.5)
                      : (isHighlighted
                          ? themeColor.withValues(alpha: 0.1)
                          : (isBeingDragged
                              ? const Color(0xFF101722)
                              : const Color(0xFF0A0F16))),
              borderRadius: BorderRadius.circular(6),
              border:
                  isHighlighted
                      ? Border.all(color: themeColor, width: 2.0)
                      : Border.all(
                        color: isProtecting 
                            ? const Color(0xFFFF4444) 
                            : coreColor.withValues(alpha: 0.6),
                        width: isProtecting ? 2 : 1,
                      ),
              boxShadow:
                  isHighlighted
                      ? [
                        BoxShadow(
                          color: themeColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                      : [
                        BoxShadow(
                          color: isProtecting
                              ? const Color(0xFFFF4444).withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.5),
                          blurRadius: isProtecting ? 10 : 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
            ),
            child: Stack(
              children: [
                // 增加装饰背景
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomPaint(
                      painter: CyberCornerPainter(
                        color: coreColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05.clamp(0.0, 1.0),
                    child: CyberScanline(color: coreColor),
                  ),
                ),
                Center(
                  child: _idleAnimationWrapper(
                    id: "monster_${program.id}",
                    isMonster: true,
                    child: Icon(
                      isDead ? Icons.dangerous : Icons.pest_control,
                      size: 42 * s,
                      color:
                          isDead
                              ? Colors.white24
                              : coreColor.withValues(alpha: 0.8),
                      shadows: [
                        if (!isDead)
                          Shadow(
                            color: coreColor.withValues(alpha: 0.5),
                            blurRadius: (isHighlighted ? 15 : 10) * s,
                          ),
                      ],
                    ),
                  ),
                ),
                if (isProtecting)
                  // 防御脉冲外圈
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 1.2),
                    duration: const Duration(milliseconds: 500),
                    builder: (_, val, __) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFFF4444).withValues(alpha: (1.0 - (val - 1.0) * 5).clamp(0.0, 1.0)),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        final box = TweenAnimationBuilder<double>(
          key: ValueKey("monster_anim_builder_${program.id}_${isGlitching}_${isProtecting}_$isBouncing"),
          duration: Duration(milliseconds: isGlitching ? 400 : (isBouncing ? 450 : 200)),
          tween: Tween(begin: 0, end: 1),
          curve: isBouncing ? Curves.easeOutBack : Curves.linear,
          builder: (context, t, child) {
            double dx = 0, dy = 0;
            double scale = 1.0;
            double rotation = 0.0;

            if (isGlitching) {
              // 更加剧烈的故障抖动
              dx = sin(t * 8 * pi) * 8 * (1 - t);
              rotation = sin(t * 4 * pi) * 0.05 * (1 - t);
              scale = 1.0 - 0.05 * sin(t * pi);
            }

            if (isBouncing) {
              // 更加平滑的弹跳
              dy -= sin(t * pi) * 12; 
              scale = 1.0 + 0.08 * sin(t * pi);
            }

            Widget content = buildCore();

            if (isGlitching) {
              // 增强故障闪烁效果
              content = ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: (0.7 * (1 - t)).clamp(0.0, 1.0)),
                  BlendMode.srcATop,
                ),
                child: content,
              );
            }

            return Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: scale,
                  child: content,
                ),
              ),
            );
          },
        );
        final statusText =
            !isDead && isHighlighted ? "目标锁定" : (isDead ? "进程已销毁" : null);
        String? intentText;
        IconData? intentIcon;
        String? intentValueText;
        Color? intentColor;
        switch (program.intent) {
          case SystemIntent.impact:
            intentText = "即将进攻";
            intentIcon = Icons.gps_fixed;
            intentValueText = "${program.intentValue}";
            intentColor = Colors.redAccent;
            break;
          case SystemIntent.encrypt:
            intentText = "即将防御";
            intentIcon = Icons.shield_rounded;
            intentValueText = "${program.intentValue}";
            intentColor = themeColor;
            break;
          case SystemIntent.repair:
            intentText = "即将恢复";
            intentIcon = Icons.healing_rounded;
            intentValueText = "${program.intentValue}";
            intentColor = Colors.greenAccent;
            break;
          case SystemIntent.summon:
            intentText = "即将召唤";
            intentIcon = Icons.group_add_rounded;
            intentColor = const Color(0xFFE26CFF);
            break;
          default:
            intentText = "未知？？";
            intentIcon = Icons.help_outline_rounded;
            intentColor = Colors.grey;
        }

        return RepaintBoundary(
          child: AnimatedOpacity(
            key: program.key,
            opacity: (isDead ? 0.4 : 1.0).clamp(0.0, 1.0),
            duration: const Duration(milliseconds: 100),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                box,
                Positioned(
                  top: 10 * s,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 90 * s),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        program.name,
                        style: TextStyle(
                          fontSize: (12 * s).clamp(9, 12),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE1E9FF),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 4 * s,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isDead)
                  Positioned(
                    top: -65 * s,
                    child: _cyberIntentBar(
                      text: intentText,
                      icon: intentIcon,
                      value: intentValueText,
                      width: (110 * s).clamp(80, 110),
                      color: intentColor ?? themeColor,
                      s: s,
                    ),
                  ),
                Positioned(
                  top: (-42 * s), // 稍微调高一点以容纳血条
                  child: Column(
                    children: [
                      _cyberHpBar(
                        current: program.hp,
                        maxHp: program.maxHp,
                        width: (100 * s).clamp(70, 100), // 敌方血条稍窄
                        height: (18 * s).clamp(12, 18),
                        label: "",
                        color: isDead ? Colors.grey : (isHighlighted ? themeColor : const Color(0xFFE1E9FF)), // 增加主题色关联
                        isMonster: true,
                      ),
                      if (program.block > 0) ...[
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          key: ValueKey("monster_block_${program.block}"),
                          tween: Tween(begin: 1.2, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, val, child) {
                            final Color blockColor = themeColor;
                            return Transform.scale(
                              scale: val,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0F16).withValues(alpha: 0.95),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    bottomRight: Radius.circular(6),
                                  ),
                                  border: Border.all(color: blockColor, width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: blockColor.withValues(alpha: 0.3),
                                      blurRadius: 6 * s,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shield_outlined, size: 10 * s, color: blockColor),
                                    SizedBox(width: 4 * s),
                                    Text(
                                      "FWL",
                                      style: TextStyle(
                                        color: themeColor,
                                        fontSize: (8 * s).clamp(6, 8),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    SizedBox(width: 3 * s),
                                    Text(
                                      "${program.block}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: (11 * s).clamp(8, 11),
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 4),
                      _statusEffectsBar(program),
                    ],
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
                        gradient: LinearGradient(
                          colors: [
                            isDead ? const Color(0xFF252525) : themeColor.withValues(alpha: 0.2),
                            const Color(0xFF101722),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomRight: Radius.circular(10),
                        ),
                        border: Border.all(
                          color: isDead ? const Color(0xFF444444) : themeColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isDead ? Colors.white38 : Colors.white,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pileWidget(IconData icon, int count, Color color, {required bool isDrawPile, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0F16).withValues(alpha: 0.9),
              const Color(0xFF1A1F26).withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.only(
            topRight: isDrawPile ? const Radius.circular(16) : Radius.zero,
            topLeft: isDrawPile ? Radius.zero : const Radius.circular(16),
          ),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 装饰性微光
            Positioned(
              top: -10,
              left: -10,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 2000),
                    builder: (context, val, child) {
                      return Opacity(
                        opacity: 0.7 + 0.3 * sin(val * pi),
                        child: Icon(icon, color: color, size: 18),
                      );
                    },
                  ),
                  const SizedBox(height: 1),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      color: color.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
                      ],
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

  /// 能量核心组件：科技感十足的数字仪表
  Widget _energyCoreWidget(Color color) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. 核心底座：非对称科幻容器
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E14).withValues(alpha: 0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // 内部动态扫描线
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomRight: Radius.circular(19),
                    ),
                    child: CyberScanline(color: color.withValues(alpha: 0.2)),
                  ),
                ),
                Positioned(
                  bottom: 4, right: 8,
                  child: Icon(Icons.settings_input_component, size: 8, color: color.withValues(alpha: 0.3)),
                ),
              ],
            ),
          ),
          
          // 2. 动态呼吸发光环
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              final opacity = 0.1 + (0.2 * (1.0 - (value - 0.5).abs() * 2));
              return Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: opacity),
                    width: 1,
                  ),
                ),
              );
            },
          ),

          // 3. 核心数值显示
          TweenAnimationBuilder<double>(
            key: ValueKey("energy_$energy"),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            tween: Tween(begin: 1.4, end: 1.0),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "当前能量",
                      style: TextStyle(
                        color: color.withValues(alpha: (0.6 + (scale - 1.0) * 2).clamp(0.0, 1.0)),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: color.withValues(alpha: (0.9 + (scale - 1.0) * 0.5).clamp(0.0, 1.0)),
                          size: 16,
                          shadows: [
                            Shadow(color: color, blurRadius: 10 * scale),
                          ],
                        ),
                        Text(
                          "$energy",
                          style: TextStyle(
                            color: color,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            height: 1.0,
                            letterSpacing: -1,
                            shadows: [
                              Shadow(
                                color: color.withValues(alpha: 0.9),
                                blurRadius: 12 * scale,
                              ),
                              if (scale > 1.0)
                                Shadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 25 * scale,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _handArea(Color themeColor) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // 手牌上方的判定区
        if (gamePhase != GamePhase.discardPhase)
          Positioned(
            left: 0,
            right: 0,
            bottom: 160 + (hand.length <= 6 ? 0 : (hand.length > 10 ? 140 : 70)),
            child: _judgementArea(themeColor),
          ),
        if (characterData.characterClass == CharacterClass.yanxin && gamePhase != GamePhase.gameOver)
          Positioned(
            right: 8,
            bottom: 120,
            child: _heatBarVertical(),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: gamePhase == GamePhase.discardPhase
              ? _discardPhaseView(themeColor)
              : _fanHandView(themeColor),
        ),
      ],
    );
  }

  Widget _heatBarVertical() {
    final isCharged = heatProgress >= 8;
    final pct = (heatProgress / 48.0).clamp(0.0, 1.0);
    final base = const Color(0xFFFF9500);
    final barW = 10.0;                                                       
    final barH = 150.0;
    final frameW = 28.0;
    return Container(
      width: frameW,
      height: barH + 36,
      padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isCharged ? base.withValues(alpha: 0.7) : base.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCharged ? base.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.45),
            blurRadius: isCharged ? 8 : 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CyberCornerPainter(color: base.withValues(alpha: 0.1)),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: frameW - 6,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "$heatProgress",
                      style: TextStyle(
                        color: isCharged ? base : base.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: barW,
                height: barH,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CyberScanline(color: base.withValues(alpha: isCharged ? 0.08 : 0.05)),
                      ),
                    ),
                    Container(
                      width: barW,
                      height: barH,
                      decoration: BoxDecoration(
                        color: const Color(0xFF05060A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: pct,
                        child: Container(
                          width: barW,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                base.withValues(alpha: 0.35),
                                base.withValues(alpha: 0.7),
                                base,
                              ],
                              stops: const [0.0, 0.7, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(color: base.withValues(alpha: 0.25), blurRadius: 5),
                            ],
                          ),
                          child: CyberScanline(color: Colors.white.withValues(alpha: isCharged ? 0.1 : 0.06)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _triggerHeatBurst() {
    if (characterData.characterClass != CharacterClass.yanxin) return;
    if (heatProgress < 8) {
      _showStatusTip("热量不足（≥8）才能爆发", Colors.orangeAccent);
      return;
    }
    final targets = activePrograms.where((m) => m.hp > 0).toList();
    if (targets.isEmpty) {
      _showStatusTip("无目标，爆发取消", Colors.orangeAccent);
      heatProgress = 0;
      setState(() {});
      return;
    }
    final rng = Random();
    final int total = heatProgress;
    int remaining = total;
    while (remaining > 0 && targets.isNotEmpty) {
      final t = targets[rng.nextInt(targets.length)];
      _applyDamage(player, t, 1, isFinal: true);
      if (t.hp <= 0) targets.remove(t);
      remaining--;
    }
    heatProgress = 0;
    GameState.heatProgress = 0;
    if (total > 0) {
      final healAmount = total;
      player.hp = (player.hp + healAmount).clamp(0, player.maxHp);
      anim.showHeal(player, healAmount);
      GameState.playerHp = player.hp;
    }
    _playHeatBurnEffect();
    checkBattleResult();
    setState(() {});
  }

  void _playHeatBurnEffect() {
    final ctx = context;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    anim.triggerFireOverlay();
    final centers = [
      size.center(Offset.zero),
      Offset(size.width * 0.25, size.height * 0.4),
      Offset(size.width * 0.75, size.height * 0.6),
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.8),
    ];
    for (int i = 0; i < centers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        anim.playGridPulse(centers[i]);
      });
    }
  }

  Widget _heatBurstButton() {
    final base = const Color(0xFFFF9500);
    final isCharged = heatProgress >= 8;
    return GestureDetector(
      onTap: isCharged ? () => _triggerHeatBurst() : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E14).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            if (isCharged)
              BoxShadow(color: base.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 1)
            else
              BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 8),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CyberCornerPainter(color: base.withValues(alpha: 0.4)),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CyberScanline(color: base.withValues(alpha: isCharged ? 0.12 : 0.06)),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 92, minHeight: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, color: isCharged ? base : base.withValues(alpha: 0.6), size: 13),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "热量爆发",
                        style: TextStyle(
                          color: isCharged ? base : base.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
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
  /// Buff 效果说明面板
  Widget _buffInfoPanel(Color themeColor) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, val, child) {
        return Opacity(
          opacity: val,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - val)),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F16).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            color: themeColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _activeBuffName!,
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeBuffName = null;
                            _activeBuffDesc = null;
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white38,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activeBuffDesc!,
                    style: const TextStyle(
                      color: Color(0xFFE1E9FF),
                      fontSize: 12,
                      height: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 手牌计数小组件
  Widget _handCountWidget(Color themeColor) {
    return Container(
      width: 50,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E14).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              // child: CyberScanline(color: themeColor.withValues(alpha: 0.1)),
              child: Container(),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: CyberCornerPainter(color: themeColor.withValues(alpha: 0.2)),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                gamePhase == GamePhase.discardPhase
                    ? Icons.auto_delete_rounded
                    : Icons.view_carousel_rounded,
                size: 10,
                color: themeColor.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                "${hand.length}",
                style: TextStyle(
                  color: themeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 关键区域：手牌扇形视图
  Widget _fanHandView(Color themeColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const cardW = 84.0;
        const cardH = 112.0;
        final n = hand.length;
        if (n == 0) {
          return Stack(
            children: [
              if (characterData.characterClass == CharacterClass.yanxin)
                Positioned(left: 78, top: 16, child: _heatBurstButton()),
              const Center(
                child: Icon(Icons.inbox_outlined, size: 28, color: Colors.white38),
              ),
            ],
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

        // 1. 核心操作：热能爆破
        if (characterData.characterClass == CharacterClass.yanxin) {
          children.add(
            Positioned(
              left: 78,
              top: 16,
              child: _heatBurstButton(),
            ),
          );
        }

        // 2. 手牌计数：根据行数贴近最上方一行上侧
        int rowsPreview = n <= 6 ? 1 : (n > 10 ? 3 : 2);
        final rowGapPreview = cardHS + 12;
        final anchorTopY = (baseY - rowGapPreview * (rowsPreview - 1)).clamp(0.0, h - cardHS - margin);
        children.add(
          Positioned(
            left: 0,
            right: 0,
            top: max(0.0, anchorTopY - 52),
            child: Center(child: _handCountWidget(themeColor)),
          ),
        );

        if (n <= 6) {
          for (int i = 0; i < n; i++) {
            final t = n == 1 ? 0.5 : i / (n - 1);
            final rot = (t - 0.5) * 2 * maxRot;
            var dx = margin + i * slot + (slot - cardWS) / 2;
            dx = dx.clamp(0.0, w - cardWS);
            final instance = hand[i];
            final card = instance.data;
            if (card == null) continue;
            children.add(
              AnimatedPositioned(
                key: ValueKey("hand_card_${instance.instanceId}"),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                left: dx,
                top: baseY,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (context, entryScale, child) {
                    return Transform.scale(
                      scale: entryScale,
                      child: Opacity(
                        opacity: entryScale.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    turns: rot / (2 * pi),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      scale: scale,
                      child: _cardView(i, instance),
                    ),
                  ),
                ),
              ),
            );
          }
        } else {
          final rows = n > 10 ? 3 : 2;
          final baseCount = n ~/ rows;
          final remainder = n % rows;
          final counts = List<int>.generate(rows, (i) => baseCount + (i < remainder ? 1 : 0));
          final rowGap = cardHS + 12;
          final rowYs = List<double>.generate(rows, (i) {
            final y = baseY - (rowGap * (rows - 1 - i));
            return y.clamp(0.0, h - cardHS - margin);
          });
          int cursor = 0;
          for (int r = 0; r < rows; r++) {
            final cnt = counts[r];
            if (cnt <= 0) continue;
            final slotR = availableW / cnt;
            final scaleR = slotR >= cardW ? 1.0 : max(0.6, slotR / cardW);
            final wsR = cardW * scaleR;
            final rotFactor = r == rows - 1 ? (maxRot * 0.6) : (r == rows - 2 ? (maxRot * 0.7) : (maxRot * 0.8));
            for (int i = 0; i < cnt; i++) {
              final idx = cursor + i;
              final t = cnt == 1 ? 0.5 : i / (cnt - 1);
              final rot = (t - 0.5) * 2 * rotFactor;
              var dx = margin + i * slotR + (slotR - wsR) / 2;
              dx = dx.clamp(0.0, w - wsR);
              final instance = hand[idx];
              final card = instance.data;
              if (card == null) continue;
              children.add(
                AnimatedPositioned(
                  key: ValueKey("hand_card_${instance.instanceId}"),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: dx,
                  top: rowYs[r],
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: scaleR,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: rot / (2 * pi),
                      child: _cardView(idx, instance),
                    ),
                  ),
                ),
              );
            }
            cursor += cnt;
          }
        }

        return Stack(children: children);
      },
    );
  }

  /// 弃牌阶段界面：让玩家选择保留哪张牌（使用与扇形视图一致的布局）
  Widget _discardPhaseView(Color themeColor) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              const cardW = 84.0;
              const cardH = 112.0;
              final n = hand.length;
              if (n == 0) {
                return Stack(
                  children: [
                    if (characterData.characterClass == CharacterClass.yanxin)
                      Positioned(left: 78, top: 16, child: _heatBurstButton()),
                    const Center(
                      child: Icon(Icons.inbox_outlined, size: 28, color: Colors.white38),
                    ),
                  ],
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

              // 1. 核心操作
              if (characterData.characterClass == CharacterClass.yanxin) {
                children.add(
                  Positioned(
                    left: 78,
                    top: 16,
                    child: _heatBurstButton(),
                  ),
                );
              }

              // 2. 手牌计数
              children.add(
                Positioned(
                  left: 0,
                  right: 0,
                  top: max(0.0, baseY - 48),
                  child: Center(child: _handCountWidget(themeColor)),
                ),
              );

              if (n <= 6) {
                for (int i = 0; i < n; i++) {
                  final t = n == 1 ? 0.5 : i / (n - 1);
                  final rot = (t - 0.5) * 2 * maxRot;
                  var dx = margin + i * slot + (slot - cardWS) / 2;
                  dx = dx.clamp(0.0, w - cardWS);
                  final instance = hand[i];
                  final card = instance.data;
                  if (card == null) continue;
                  children.add(
                    AnimatedPositioned(
                      key: ValueKey("discard_card_${instance.instanceId}"),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      left: dx,
                      top: baseY,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        builder: (context, entryScale, child) {
                          return Transform.scale(
                            scale: entryScale,
                            child: Opacity(
                              opacity: entryScale.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () => selectCardToKeep(instance),
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            turns: rot / (2 * pi),
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              scale: scale,
                              child: _cardView(i, instance),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              } else {
                final rows = n > 10 ? 3 : 2;
                final baseCount = n ~/ rows;
                final remainder = n % rows;
                final counts = List<int>.generate(rows, (i) => baseCount + (i < remainder ? 1 : 0));
                final rowGap = cardHS + 12;
                final rowYs = List<double>.generate(rows, (i) {
                  final y = baseY - (rowGap * (rows - 1 - i));
                  return y.clamp(0.0, h - cardHS - margin);
                });
                int cursor = 0;
                for (int r = 0; r < rows; r++) {
                  final cnt = counts[r];
                  if (cnt <= 0) continue;
                  final slotR = availableW / cnt;
                  final scaleR = slotR >= cardW ? 1.0 : max(0.6, slotR / cardW);
                  final wsR = cardW * scaleR;
                  final rotFactor = r == rows - 1 ? (maxRot * 0.6) : (r == rows - 2 ? (maxRot * 0.7) : (maxRot * 0.8));
                  for (int i = 0; i < cnt; i++) {
                    final idx = cursor + i;
                    final t = cnt == 1 ? 0.5 : i / (cnt - 1);
                    final rot = (t - 0.5) * 2 * rotFactor;
                    var dx = margin + i * slotR + (slotR - wsR) / 2;
                    dx = dx.clamp(0.0, w - wsR);
                    final instance = hand[idx];
                    final card = instance.data;
                    if (card == null) continue;
                    children.add(
                      AnimatedPositioned(
                        key: ValueKey("discard_card_${instance.instanceId}"),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: dx,
                        top: rowYs[r],
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: scaleR,
                          child: GestureDetector(
                            onTap: () => selectCardToKeep(instance),
                            child: AnimatedRotation(
                              duration: const Duration(milliseconds: 300),
                              turns: rot / (2 * pi),
                              child: _cardView(idx, instance),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  cursor += cnt;
                }
              }

              return Stack(children: children);
            },
          ),
        ),
        // 底部提示文字
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            "选择保留一张卡牌，其余的将会进入弃牌堆",
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade800.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardView(int index, CardInstance instance) {
    final card = instance.data;
    if (card == null) return const SizedBox.shrink();
    final instanceId = instance.instanceId;

    return Stack(
      children: [
        Draggable<CardInstance>(
          data: instance,

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

          /// 🔑 优化点 1：使用 TweenAnimationBuilder 实现更柔和的弹出反馈
          feedback: Material(
            color: Colors.transparent,
            elevation: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              builder: (context, t, child) {
                return Transform.scale(
                  scale: 1.0 + 0.1 * t, // 稍微放大
                  child: Transform.rotate(
                    angle: 0.05 * t, // 轻微旋转
                    child: Opacity(
                      opacity: (0.8 + 0.2 * t).clamp(0.0, 1.0),
                      child: SizedBox(
                        width: 84,
                        height: 112,
                        child: _cardWidget(card, dragging: true),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// 🔑 优化点 2：拖拽时原位置显示动态占位，增加吸附感
          childWhenDragging: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 350),
            tween: Tween(begin: 1.0, end: 0.4),
            curve: Curves.easeOutQuart,
            builder: (context, opacity, child) {
              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.92, 
                  child: Container(
                    width: 84,
                    height: 112,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.hourglass_empty,
                        color: Colors.white.withValues(alpha: 0.2),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          child: KeyedSubtree(
            key: _cardKeys[index] ??= GlobalKey(),
            child: SizedBox(
              width: 84,
              height: 112,
              // 🔧 修复：扫描动画期间隐藏正常卡牌，扫描完成后再显示
              child:
                  _dealingCards.contains(instanceId) &&
                          _cardAnimationControllers.containsKey(instanceId) &&
                          _cardAnimationControllers[instanceId]!.value < 1.0
                      ? const SizedBox.shrink() // 扫描未完成时不显示
                      : _cardWidget(card),
            ),
          ),
        ),
        // 摸牌扫描带动画
        if (_dealingCards.contains(instanceId) &&
            _cardAnimationControllers.containsKey(instanceId))
          AnimatedBuilder(
            animation: _cardAnimationControllers[instanceId]!,
            builder: (context, child) {
              Color getScanColor() {
                switch (card.suite) {
                  case CardSuite.classic: return ThemeConfig.defaultCardColor;
                  case CardSuite.overload: return const Color(0xFFFF4444);
                  case CardSuite.secure: return const Color(0xFFC3A6FF);
                  case CardSuite.industrial: return const Color(0xFFFFB344);
                  case CardSuite.quantum: return const Color(0xFFE26CFF);
                  case CardSuite.demon: return const Color(0xFF9D00FF);
                  case CardSuite.holy: return const Color(0xFFFFD700);
                }
              }

              final scanColor = getScanColor();
              final progress = _cardAnimationControllers[instanceId]!.value;
              
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
                    width: 84,
                    height: 112,
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
                    child: CustomPaint(
                      painter: CyberGridPainter(
                        color: scanColor,
                        opacity: 0.5,
                        spacing: 12.0,
                        showChars: false,
                        strokeWidth: 1.0,
                      ),
                    ),
                  ),
                  // 扫描线
                  Positioned(
                    left: 0,
                    right: 0,
                    top: progress * 112 - 4,
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
                      opacity: ((progress - 0.8) * 5).clamp(0.0, 1.0), // 0.8-1.0区间渐变
                      child: completionProgress >= 1.0 ? zoomEffect : child,
                    ),
                ],
              );
            },
            child: SizedBox(width: 84, height: 112, child: _cardWidget(card)),
          ),
        // 弃牌扫描带动画
        if (_discardingCards.contains(instanceId) &&
            _cardAnimationControllers.containsKey(instanceId))
          AnimatedBuilder(
            animation: _cardAnimationControllers[instanceId]!,
            builder: (context, child) {
              Color getScanColor() {
                switch (card.suite) {
                  case CardSuite.classic: return ThemeConfig.defaultCardColor;
                  case CardSuite.overload: return const Color(0xFFFF4444);
                  case CardSuite.secure: return const Color(0xFFC3A6FF);
                  case CardSuite.industrial: return const Color(0xFFFFB344);
                  case CardSuite.quantum: return const Color(0xFFE26CFF);
                  case CardSuite.demon: return const Color(0xFF9D00FF);
                  case CardSuite.holy: return const Color(0xFFFFD700);
                }
              }

              final scanColor = getScanColor();
              final progress = _cardAnimationControllers[instanceId]!.value;
              
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
                    width: 84,
                    height: 112,
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
                    child: CustomPaint(
                      painter: CyberGridPainter(
                        color: scanColor,
                        opacity: 0.5,
                        spacing: 12.0,
                        showChars: false,
                        strokeWidth: 1.0,
                      ),
                    ),
                  ),
                  // 扫描线 - 从上往下移动
                  Positioned(
                    left: 0,
                    right: 0,
                    top: progress * 112 - 4,
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
                      opacity: ((progress - 0.8) * 5).clamp(0.0, 1.0), // 0.8-1.0区间渐变
                      child: completionProgress >= 1.0 ? zoomEffect : child,
                    ),
                ],
              );
            },
            child: SizedBox(width: 84, height: 112, child: _cardWidget(card)),
          ),
      ],
    );
  }

  // 获取目标显示图标和颜色
  Widget getTargetIcon(CardTarget target) {
    switch (target) {
      case CardTarget.enemy:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gps_fixed,
              size: 10,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 2),
            Text(
              "目标主机",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        );
      case CardTarget.self:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              size: 10,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 2),
            Text(
              "核心节点",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        );
      case CardTarget.all:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.public,
              size: 10,
              color: Colors.purple.shade700,
            ),
            const SizedBox(width: 2),
            Text(
              "全域广播",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ],
        );
    }
  }

  Widget _cardWidget(
    CardData c, {
    bool dragging = false,
    bool showCompleteAnimation = false,
    double width = 84,
    double height = 112,
  }) {
    if (showCompleteAnimation) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 1.5, end: 1.0),
        curve: Curves.bounceOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: ThemeConfig.buildCardWidget(c, dragging: dragging, width: width, height: height),
        ),
      );
    } else {
      return ThemeConfig.buildCardWidget(c, dragging: dragging, width: width, height: height);
    }
  }


  // 关键区域：攻击特效分发中心
  Widget _attackEffect(AttackEffect e) {
    switch (e.type) {
      case AttackEffectType.laser:
        return LaserEffectWidget(e);
      case AttackEffectType.slash:
        return SlashEffectWidget(e);
      case AttackEffectType.explosion:
        return ExplosionEffectWidget(e);
      case AttackEffectType.inject:
        return InjectEffectWidget(e);
      case AttackEffectType.impact:
        return ImpactEffectWidget(e);
    }
  }

  // 关键区域：特效分组渲染（分层减少全局重建）
  Widget _attackGroup(AttackEffectType type) {
    final items = anim.attacks.where((e) => e.type == type).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      child: RepaintBoundary(
        child: Stack(children: items.map(_attackEffect).toList()),
      ),
    );
  }

// End of BattlePage class

  Widget _statusIcon(IconData icon, String value, Color color, String tooltip) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          if (_activeBuffName == tooltip) {
            _activeBuffName = null;
            _activeBuffDesc = null;
          } else {
            _activeBuffName = tooltip;
            _activeBuffDesc = _buffExplanations[tooltip] ?? "暂无说明";
          }
        });
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1500),
        builder: (context, animVal, child) {
          final isHighlighted = _activeBuffName == tooltip;
          
          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 36, minHeight: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: isHighlighted ? 0.3 : 0.1),
                    color.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  bottomRight: Radius.circular(10),
                ),
                border: Border.all(
                  color: isHighlighted ? color : color.withValues(alpha: 0.3),
                  width: isHighlighted ? 1.5 : 0.8,
                ),
                boxShadow: [
                  if (isHighlighted)
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.05,
                      // child: CyberScanline(color: color),
                      child: Container(),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1500),
                        builder: (context, val, child) {
                          return Opacity(
                            opacity: isHighlighted ? 1.0 : (0.7 + 0.3 * sin(val * pi)),
                            child: Icon(icon, size: 12, color: color),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        value,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: isHighlighted ? 4 : 2,
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
        },
      ),
    );
  }

  Widget _statusEffectsBar(Entity e) {
    final effects = <Widget>[];

    final int normalStrength = e.strength;
    int bloodBonus = e.bloodStrength;

    // 自动更新血液算力数值（仅限玩家血液角色）：损失生命/10（四舍五入）
    if (e == player && characterData.characterClass == CharacterClass.xueye) {
      bloodBonus = ((e.maxHp - e.hp) / 10.0).round();
      e.bloodStrength = bloodBonus;
    }

    if (normalStrength > 0) {
      effects.add(
        _statusIcon(
          Icons.bolt,
          "$normalStrength",
          Colors.orangeAccent,
          "算力",
        ),
      );
    }
    if (bloodBonus > 0) {
      effects.add(
        _statusIcon(
          Icons.bolt,
          "$bloodBonus",
          Colors.redAccent,
          "血液算力",
        ),
      );
    }
    if (e.tempStrength > 0) {
      effects.add(
        _statusIcon(
          Icons.bolt,
          "${e.tempStrength}",
          const Color(0xFFC3A6FF),
          "临时算力",
        ),
      );
    }
    if (e.weak > 0) {
      effects.add(
        _statusIcon(Icons.trending_down, "${e.weak}", Colors.yellowAccent, "虚弱"),
      );
    }
    if (e.vulnerable > 0) {
      effects.add(
        _statusIcon(
          Icons.heart_broken,
          "${e.vulnerable}",
          Colors.redAccent,
          "漏洞暴露",
        ),
      );
    }
    if (e.curse > 0) {
      effects.add(
        _statusIcon(Icons.bug_report, "${e.curse}", Colors.purpleAccent, "恶意代码"),
      );
    }
    if (e.sturdy > 0) {
      effects.add(
        _statusIcon(Icons.shield, "${e.sturdy}", _getThemeColor(), "坚固"),
      );
    }
    if (e.fire > 0) {
      effects.add(
        _statusIcon(Icons.local_fire_department, "${e.fire}", const Color(0xFFFF9500), "火焰"),
      );
    }

    if (effects.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: SizedBox(
          height: 26,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: effects
                  .map((w) => Padding(padding: const EdgeInsets.only(right: 6), child: w))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  // 显示卡牌使用时的粒子效果
  void _showCardUseEffect(CardData card, Entity target) {
    // 增加玩家模型的小弹跳反馈
    anim.showActionFeedback(player);
    
    // 根据卡牌类型添加不同的粒子效果反馈
    final ctx = target.key.currentContext;
    if (ctx == null) return;
    
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(const Offset(50, 20));
    
    // 触发屏幕抖动或颜色反馈
    if (card.type == CardType.exploit) {
      anim.triggerScreenOverload();
      // 在目标位置产生一个冲击波效果
      final p = GamePopup(
        value: "0",
        pos: pos,
        type: PopupType.damage,
      );
      anim.gamePopups.add(p);
      anim.refresh();
      Future.delayed(const Duration(milliseconds: 1200), () {
        anim.gamePopups.remove(p);
        anim.refresh();
      });
    } else if (card.type == CardType.encryption) {
      anim.showActionFeedback(target);
    }
  }

  // 关键区域：防火墙崩溃特效
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
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: o.dx.sign * 0.4 * t,
                      child: Icon(
                        Icons.shield,
                        size: 14 + 6 * (1 - t),
                        color: _getThemeColor(),
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
    final cardId = m.instanceId.contains('_') ? m.instanceId.split('_')[0] : m.instanceId;
    final card = cardDatabase[cardId];
    if (card == null) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650), // 增加时长使动作更优雅
      curve: Curves.easeOutQuart, // 使用更平滑的减速曲线
      builder: (_, t, __) {
        // 弧形路径：在直线移动的基础上增加一点垂直弧度
        final arc = sin(t * pi) * 20;
        final x = m.start.dx + (m.end.dx - m.start.dx) * t;
        final y = m.start.dy + (m.end.dy - m.start.dy) * t - arc;
        
        // 动态缩放：先缩小再恢复，模拟从手牌抽出的动态
        final s = 0.85 + 0.15 * Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
        
        // 动态旋转：根据移动方向增加倾斜感
        final horizontalShift = (m.end.dx - m.start.dx).clamp(-50, 50) / 50.0;
        final rot = (m.start.dy > m.end.dy ? -0.2 : 0.15) * (1 - t) + (horizontalShift * 0.1 * t);
        
        // 透明度：更加平滑的淡入
        final opacity = (t * 2).clamp(0.0, 1.0);
        
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

  // 关键区域：查看牌堆内容的弹窗 - 深度美化版
  void _showCardListDialog(String title, List<CardInstance> cards, Color color) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // 1. 基础背景层：极简深色与高强度模糊
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomRight: Radius.circular(30),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF05070A).withValues(alpha: 0.95),
                              const Color(0xFF0A0F16).withValues(alpha: 0.95),
                            ],
                          ),
                          border: Border.all(
                            color: color.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.03,
                                // child: CyberScanline(color: color),
                                child: Container(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. 装饰性：数字网格背景 (科幻感核心)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.05,
                        child: CustomPaint(
                          painter: CyberGridPainter(color: color),
                        ),
                      ),
                    ),
                  ),

                  // 3. 装饰性：角落系统编号
                  Positioned(
                    top: 10, left: 20,
                    child: Text(
                      "MEM_ADDR: 0x${cards.hashCode.toRadixString(16).toUpperCase()}",
                      style: TextStyle(color: color.withValues(alpha: 0.3), fontSize: 8, fontFamily: 'monospace'),
                    ),
                  ),
                  Positioned(
                    bottom: 10, right: 20,
                    child: Text(
                      "BUFFER_STATUS: SECURE",
                      style: TextStyle(color: color.withValues(alpha: 0.3), fontSize: 8, fontFamily: 'monospace'),
                    ),
                  ),

                  // 4. 内容层
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题栏：HUD 风格
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.terminal, color: color, size: 14),
                                    const SizedBox(width: 8),
                                    Text(
                                      "SYSTEM.FILE_VISUALIZER // V4.02",
                                      style: TextStyle(
                                        color: color.withValues(alpha: 0.5),
                                        fontSize: 9,
                                        letterSpacing: 2,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Stack(
                                  children: [
                                    Text(
                                      title.toUpperCase(),
                                      style: TextStyle(
                                        color: color.withValues(alpha: 0.1),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 6,
                                        fontSize: 26,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2, left: 2),
                                      child: Text(
                                        title.toUpperCase(),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 6,
                                          fontSize: 24,
                                          fontFamily: 'monospace',
                                          shadows: [
                                            Shadow(color: color.withValues(alpha: 0.5), blurRadius: 15),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                          ],
                        ),
                        
                        const SizedBox(height: 30),

                        // 卡牌列表
                        Expanded(
                          child: cards.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.layers_clear, color: color.withValues(alpha: 0.2), size: 80),
                                      const SizedBox(height: 20),
                                      Text(
                                        "NULL_POINTER // 无可用指令",
                                        style: TextStyle(
                                          color: color.withValues(alpha: 0.4),
                                          fontSize: 14,
                                          letterSpacing: 5,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Theme(
                                  data: ThemeData.dark().copyWith(
                                    scrollbarTheme: ScrollbarThemeData(
                                      thumbColor: WidgetStateProperty.all(color.withValues(alpha: 0.3)),
                                      thickness: WidgetStateProperty.all(2),
                                      radius: Radius.zero,
                                    ),
                                  ),
                                  child: Scrollbar(
                                    child: GridView.builder(
                                      padding: const EdgeInsets.only(right: 16),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.7,
                                        crossAxisSpacing: 24,
                                        mainAxisSpacing: 24,
                                      ),
                                      itemCount: cards.length,
                                      itemBuilder: (context, index) {
                                        final card = cards[index].data;
                                        if (card == null) return const SizedBox.shrink();
                                        return _cardWidget(card);
                                      },
                                    ),
                                  ),
                                ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // 底部关闭按钮：改为更像系统指令
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 220,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withValues(alpha: 0.1),
                                    color.withValues(alpha: 0.02),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(2),
                                  bottomRight: Radius.circular(12),
                                ),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: 0.05,
                                    // child: CyberScanline(color: color),
                                    child: Container(),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "> DISCONNECT_STREAM",
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          shadows: [
                                            Shadow(color: color.withValues(alpha: 0.3), blurRadius: 4),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _BlinkingCursor(color: color),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: (1 - anim1.value) * 10, sigmaY: (1 - anim1.value) * 10),
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// 弹窗扫描线动画
/// 战斗全局背景
class _BattleBackground extends StatelessWidget {
  final List<GridPulse> pulses;
  final Color gridColor;
  const _BattleBackground({required this.pulses, required this.gridColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 基础渐变
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF05060A), Color(0xFF0C1018)],
            ),
          ),
        ),
        // 网格层
        Positioned.fill(
          child: CustomPaint(
            painter: CyberBattleGridPainter(pulses: pulses, gridColor: gridColor),
          ),
        ),
      ],
    );
  }
}



/// 闪烁光标
class _BlinkingCursor extends StatefulWidget {
  final Color color;
  const _BlinkingCursor({required this.color});
  @override
  _BlinkingCursorState createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(width: 8, height: 16, color: widget.color),
    );
  }
}

/// 循环空闲动画组件，解决模型动画不循环和性能问题
class _LoopingIdleWidget extends StatefulWidget {
  final Widget child;
  final bool isMonster;
  final String id;

  const _LoopingIdleWidget({
    required this.child,
    required this.isMonster,
    required this.id,
  });

  @override
  _LoopingIdleWidgetState createState() => _LoopingIdleWidgetState();
}

class _LoopingIdleWidgetState extends State<_LoopingIdleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.isMonster ? 3 : 2),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: widget.isMonster ? 0.9 : 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          double dy = 0;
          if (widget.isMonster) {
            // 怪物悬浮效果：随缩放同步上下漂浮，使其更自然
            dy = (_controller.value - 0.5) * 4;
          }
          
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: _animation.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
