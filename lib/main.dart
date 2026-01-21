/**
 * 游戏主逻辑文件，包含战斗系统、卡牌渲染、Buff 说明浮层等核心 UI 与逻辑实现。
 */
import 'dart:math';
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
import 'laser_painter.dart';
import 'slash_painter.dart';
import 'animation_constants.dart';
import 'effect_styles.dart';
import 'scanline_jitter_painter.dart';
import 'effects_widgets.dart';

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
  syncPhase, // 同步阶段（原同步阶段）
  discardPhase, // 弃牌阶段
  systemResponse, // 系统响应（原系统响应阶段）
  gameOver, // 游戏结束
}

enum SystemIntent { impact, encrypt, repair }

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
  int vulnerable = 0; // 脆弱：受到额外冲击
  int weak = 0; // 虚弱：造成冲击减少
  int strength = 0; // 算力：增加造成的冲击
  int curse = 0; // 诅咒：恶意代码层数

  Entity(this.name, this.hp, {int? maxHp}) : maxHp = maxHp ?? hp;
}

/// =====================
/// 系统冲击弹窗
/// =====================

class DamagePopup {
  final int value;
  final Offset pos;
  DamagePopup(this.value, this.pos);
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

/// 关键区域：防火墙冲击弹窗
class BlockPopup {
  final int value;
  final Offset pos;
  BlockPopup(this.value, this.pos);
}

/// 关键区域：防火墙崩溃特效
class ShieldBreakEffect {
  final Offset center;
  ShieldBreakEffect(this.center);
}

/// 关键区域：防火墙加固弹窗
class BlockGainPopup {
  final int value;
  final Offset pos;
  BlockGainPopup(this.value, this.pos);
}

/// 关键区域：背景网格脉冲效果
class GridPulse {
  final Offset center;
  final DateTime startTime;
  GridPulse(this.center) : startTime = DateTime.now();
}

/// 关键区域：角色专属特效
class RoleEffect {
  final CharacterClass role;
  final Offset pos;
  final DateTime startTime;
  RoleEffect(this.role, this.pos) : startTime = DateTime.now();
}

/// 关键区域：系统修复弹窗
class HealPopup {
  final int value;
  final Offset pos;
  HealPopup(this.value, this.pos);
}

class AnimationService extends ChangeNotifier {
  final List<DamagePopup> popups = [];
  final List<AttackEffect> attacks = [];
  final List<GridPulse> gridPulses = []; // 网格脉冲效果列表
  final List<RoleEffect> roleEffects = []; // 角色专属特效列表
  final Set<Entity> protecting = {}; // 防御脉冲状态
  final Set<Entity> glitching = {}; // 数据过载/故障状态
  final Set<Entity> bouncing = {}; // 使用卡牌时的弹跳状态
  bool isScreenOverloaded = false; // 全局数据过载状态
  final List<CardMotion> motions = [];
  final List<BlockPopup> blockPopups = [];
  final List<ShieldBreakEffect> shieldBreaks = [];
  final List<BlockGainPopup> blockGains = [];
  final List<HealPopup> healPopups = [];
  bool fireOverlayActive = false;
  DateTime? fireOverlayStart;
  bool hpDamageFlashActive = false;
  int? lastPlayerDamage;
  DateTime? lastPlayerDamageAt;

  void showDamage(Entity target, int value) {
    final ctx = target.key.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(const Offset(50, 10));

    glitching.add(target); // 开启数据故障效果
    final p = DamagePopup(value, pos);
    popups.add(p);
    notifyListeners();

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

    Future.delayed(const Duration(milliseconds: 800), () {
      popups.remove(p);
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
    final ctx = target.key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
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
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
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
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(const Offset(60, 100));

    protecting.add(target); // 开启防御脉冲
    final b = BlockGainPopup(value, pos);
    blockGains.add(b);
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      protecting.remove(target); // 停止脉冲
      notifyListeners();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      blockGains.remove(b);
      notifyListeners();
    });
  }

  void showHeal(Entity target, int value) {
    final ctx = target.key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(const Offset(50, 10));
    final h = HealPopup(value, pos);
    healPopups.add(h);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 800), () {
      healPopups.remove(h);
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

// 已迁移激光与斩击画笔到独立文件，移除旧定义

/// 关键区域：角色专属特效绘制（海浪线条等）
class RoleEffectPainter extends CustomPainter {
  final List<RoleEffect> effects;
  RoleEffectPainter(this.effects);

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    for (final effect in effects) {
      final elapsed = now.difference(effect.startTime).inMilliseconds;
      final progress = (elapsed / 1500).clamp(0.0, 1.0);

      switch (effect.role) {
        case CharacterClass.langchao:
          _drawLangWave(canvas, size, effect.pos, progress);
          break;
        case CharacterClass.xueye:
          break;
        case CharacterClass.lin:
          _drawLinShieldEffect(canvas, size, effect.pos, progress);
          break;
        case CharacterClass.jianren:
          break;
        case CharacterClass.yanxin:
          _drawFireParticles(canvas, size, effect.pos, progress);
          break;
        case CharacterClass.yingshi:
          _drawShadowFade(canvas, size, effect.pos, progress);
          break;
        case CharacterClass.jihe:
          _drawHexGrid(canvas, size, effect.pos, progress);
          break;
        case CharacterClass.xuxing:
          _drawGlitchSquares(canvas, size, effect.pos, progress);
          break;
        case CharacterClass.fa:
          _drawFaWaves(canvas, size, progress);
          break;
      }
    }
  }

  // 林：粉紫色光辉汇聚为护盾
  void _drawLinShieldEffect(Canvas canvas, Size size, Offset center, double progress) {
    final pink = const Color(0xFFC3A6FF);
    final purple = const Color(0xFF7A3BFF);
    final bgAlpha = (1.0 - progress).clamp(0.0, 1.0);
    final beamAlpha = (0.8 - progress).clamp(0.0, 0.8);
    final shieldAlpha = (1.0 - progress).clamp(0.0, 1.0);
    final leftShader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [purple.withValues(alpha: beamAlpha * 0.6), pink.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final rightShader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [purple.withValues(alpha: beamAlpha * 0.6), pink.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final leftW = size.width * 0.35 * (1.0 - progress);
    final rightW = size.width * 0.35 * (1.0 - progress);
    canvas.drawRect(Rect.fromLTWH(0, 0, leftW, size.height), Paint()..shader = leftShader);
    canvas.drawRect(Rect.fromLTWH(size.width - rightW, 0, rightW, size.height), Paint()..shader = rightShader);
    final rand = Random(131);
    for (int i = 0; i < 18; i++) {
      final a = rand.nextDouble() * pi * 2;
      final r = size.width * 0.28 * (1.0 - progress);
      final x = center.dx + cos(a) * r;
      final y = center.dy + sin(a) * r;
      final p = Paint()..color = pink.withValues(alpha: bgAlpha * 0.6);
      canvas.drawCircle(Offset(x, y), 2 + rand.nextDouble() * 3, p);
    }
    final ringOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = pink.withValues(alpha: shieldAlpha * 0.6);
    final ringInner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = purple.withValues(alpha: shieldAlpha * 0.4);
    final rBase = 42.0 + 16.0 * progress;
    canvas.drawCircle(center, rBase, ringOuter);
    canvas.drawCircle(center, rBase - 6, ringInner);
    final hex = Path();
    final hexR = 26.0 + 10.0 * progress;
    for (int i = 0; i < 6; i++) {
      final a = (pi / 3) * i;
      final vx = center.dx + cos(a) * hexR;
      final vy = center.dy + sin(a) * hexR;
      if (i == 0) hex.moveTo(vx, vy); else hex.lineTo(vx, vy);
    }
    hex.close();
    canvas.drawPath(hex, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = purple.withValues(alpha: shieldAlpha * 0.5));
  }
  void _drawLangWave(Canvas canvas, Size size, Offset center, double progress) {
    final base = const Color(0xFF4DCCFF);
    final p = progress.clamp(0.0, 1.0);
    final h = size.height * p;
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        base.withValues(alpha: 0.28 * (1.0 - p)),
        base.withValues(alpha: 0.18 * (1.0 - p)),
        Colors.transparent,
      ],
      stops: const [0.0, 0.8, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h), Paint()..shader = shader);
    final crestY = h + 6.0;
    for (int i = 0; i < 2; i++) {
      final amp = 14.0 - i * 4.0;
      final freq = 0.010 + i * 0.003;
      final phase = p * 10.0 + i * 1.7;
      final path = Path()..moveTo(0, crestY + amp * sin(phase));
      for (double x = 0; x <= size.width; x += 6) {
        final y = crestY + amp * sin(x * freq + phase);
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = base.withValues(alpha: 0.22 * (1.0 - p))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 - i * 0.4,
      );
    }
  }


  // 焰心：上升的火焰粒子
  void _drawFireParticles(Canvas canvas, Size size, Offset center, double progress) {
    final random = Random(123);
    for (int i = 0; i < 20; i++) {
      final paint = Paint()
        ..color = Color.lerp(const Color(0xFFFFD700), const Color(0xFFFF4500), random.nextDouble())!
            .withValues(alpha: (1.0 - progress) * 0.8);
      
      final x = center.dx + (random.nextDouble() - 0.5) * size.width * 0.6;
      final y = center.dy + (random.nextDouble() - 0.5) * 50 - (progress * 200); // 向上升
      
      canvas.drawCircle(Offset(x, y), 2 + random.nextDouble() * 4, paint);
    }
  }

  // 影蚀：深紫色阴影扩张
  void _drawShadowFade(Canvas canvas, Size size, Offset center, double progress) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1A0033).withValues(alpha: 0.0),
          const Color(0xFF1A0033).withValues(alpha: (1.0 - progress) * 0.4),
        ],
        stops: [0.6, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  // 几何：青色六边形网格脉冲
  void _drawHexGrid(Canvas canvas, Size size, Offset center, double progress) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: (1.0 - progress) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final hexSize = 40.0;
    final rows = (size.height / (hexSize * 1.5)).ceil();
    final cols = (size.width / (hexSize * sqrt(3))).ceil();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = c * hexSize * sqrt(3) + (r % 2 == 0 ? 0 : hexSize * sqrt(3) / 2);
        final y = r * hexSize * 1.5;
        
        final dist = (Offset(x, y) - center).distance;
        if ((dist - progress * size.width).abs() < 50) {
          _drawHex(canvas, Offset(x, y), hexSize, paint);
        }
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = pi / 3 * i;
      final x = center.dx + size * cos(angle);
      final y = center.dy + size * sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // 虚行：紫色数字故障方块
  void _drawGlitchSquares(Canvas canvas, Size size, Offset center, double progress) {
    final random = Random(777);
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (int i = 0; i < 12; i++) {
      final color = random.nextBool() ? const Color(0xFF9933FF) : const Color(0xFF00CCFF);
      paint.color = color.withValues(alpha: (1.0 - progress) * 0.6);
      
      final w = 10.0 + random.nextDouble() * 30;
      final h = 2.0 + random.nextDouble() * 5;
      final x = center.dx + (random.nextDouble() - 0.5) * size.width * 0.8 + (progress * 50 * (random.nextBool() ? 1 : -1));
      final y = center.dy + (random.nextDouble() - 0.5) * size.height * 0.4;
      
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    }
  }

  void _drawWaveLines(Canvas canvas, Size size, Offset center, double progress) {
    final paint = Paint()
      ..color = const Color(0xFF4DCCFF).withValues(alpha: (1.0 - progress) * 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveCount = 3;
    final waveWidth = size.width * 0.8;
    
    for (int i = 0; i < waveCount; i++) {
      final yOffset = center.dy + (i - 1) * 30 + sin(progress * pi * 2 + i) * 10;
      final xStart = center.dx - waveWidth / 2;
      
      path.reset();
      path.moveTo(xStart, yOffset);
      
      for (double x = 0; x <= waveWidth; x += 10) {
        final dx = xStart + x;
        final dy = yOffset + sin((x / waveWidth) * pi * 4 + progress * pi * 2 + i) * 15 * (1.0 - progress);
        path.lineTo(dx, dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawFaWaves(Canvas canvas, Size size, double progress) {
    final baseY = size.height * (1.0 - progress);
    for (int i = 0; i < 3; i++) {
      final amp = 10.0 + i * 2.0;
      final freq = 0.010 + i * 0.003;
      final phase = progress * (8.0 + i);
      final path = Path()..moveTo(0, baseY + amp * sin(phase));
      for (double x = 0; x <= size.width; x += 6) {
        final y = baseY + amp * sin(x * freq + phase);
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: (0.20 - i * 0.04).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.8 - i * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(RoleEffectPainter oldDelegate) => true;
}

class _HpBarBackgroundPainter extends CustomPainter {
  final Color color;
  _HpBarBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const double spacing = 6;
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 关键区域：全局主题
ThemeData _darkTheme() {
  final base = ThemeData.dark();
  final tt = base.textTheme;
  final spire = (TextStyle s) => s.copyWith(fontFamily: 'SpireE', fontFamilyFallback: const ['SpireC']);
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
        fontFamily: 'SpireE',
        fontFamilyFallback: ['SpireC'],
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
                    painter: _HoloGridPainter(progress: t),
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
  final List<String>? programIds;

  /// 关卡ID（用于记录进度）
  final String? levelId;
  const BattlePage({super.key, this.programIds, this.levelId});
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

  final player = Entity("接入单元", GameState.playerHp, maxHp: GameState.playerMaxHp)
    ..strength = GameState.playerStrength
    ..block = GameState.playerBlock;
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
  bool _playerTookDamageThisTurn = false; // 影蚀职业：记录本回合是否受到伤害
  CardSuite? _lastUsedSuite; // 几何职业：记录上一张使用的牌类别
  bool _yingshiInitBonusGranted = false;
  bool _interactionLocked = false;
  bool _resultScheduling = false;

  // Buff 详情查看状态
  String? _activeBuffName;
  String? _activeBuffDesc;

  static const Map<String, String> _buffExplanations = {
    "算力": "每层算力使攻击造成的伤害增加 1 点。",
    "临时算力": "每层临时算力使攻击造成的伤害增加 1 点，回合开始时 -5。",
    "血液算力": "血液被动的额外算力，基于损失生命值计算。",
    "虚弱": "每层使攻击伤害递减 25%（逐层依次计算）。",
    "脆弱": "脆弱状态下，受到攻击时受到的伤害增加 10%/层。",
    "恶意代码": "每层恶意代码使受到攻击时额外受到的伤害增加 2 点。",
    "火焰": "怪兽回合结束后造成等于层数的伤害；护盾清零；每回合层数 -1。",
    "坚固": "拥有该状态时回合结束护盾不清零，每回合 -1。",
  };

  bool _isDraggingOverJudgementArea = false; // 是否正在向判定区拖动

  // 判定区组件
  Widget _judgementArea() {
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
                  ? const Color(0xFF6CE4FF).withValues(alpha: 0.15) 
                  : const Color(0xFF6CE4FF).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHighlighted 
                    ? const Color(0xFF6CE4FF) 
                    : const Color(0xFF6CE4FF).withValues(alpha: 0.3),
                width: isHighlighted ? 2 : 1,
              ),
              boxShadow: [
                if (isHighlighted)
                  BoxShadow(
                    color: const Color(0xFF6CE4FF).withValues(alpha: 0.3),
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
                        color: const Color(0xFF6CE4FF).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: CyberScanline(color: Color(0xFF6CE4FF)),
                  ),
                ),
                Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.system_update_alt_rounded,
                        color: isHighlighted 
                            ? const Color(0xFF6CE4FF) 
                            : const Color(0xFF6CE4FF).withValues(alpha: 0.6),
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHighlighted ? "EXECUTE_SEQUENCE" : "READY_TO_UPLOAD",
                        style: TextStyle(
                          color: isHighlighted 
                              ? const Color(0xFF6CE4FF) 
                              : const Color(0xFF6CE4FF).withValues(alpha: 0.6),
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

  @override
  void initState() {
    super.initState();
    // 关键区域：根据地图节点构建系统程序
    activePrograms = _buildProgramsFromIds(widget.programIds);
    // 设置DSL效果执行器
    CardEffect.setExecutor(_executeCardEffect);
    // 获取当前角色数据
    characterData = characterDatabase[GameState.selectedCharacterId]!;
    // 焰心：跨关卡持久热量进度同步到战斗页
    heatProgress = GameState.heatProgress.clamp(0, 48);
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
    for (final controller in _cardAnimationControllers.values) {
      controller.dispose();
    }
    _cardAnimationControllers.clear();
    super.dispose();
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
    CardData card,
    dynamic target,
    dynamic battle,
  ) {
    // 分割多个效果（支持分号分隔）
    final effects = effect.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final bool isFa = characterData.characterClass == CharacterClass.fa;
    final bool isEnemyTarget = card.target == CardTarget.enemy;
    final bool isAllTarget = card.target == CardTarget.all;
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
            final total = value * repeatCount;
            player.block += total;
            anim.showBlockGain(player, total);
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
        case 'temp_strength':
          if (parts.length > 1) {
            final value = int.tryParse(parts[1]) ?? 1;
            player.tempStrength += value * repeatCount;
          }
          break;
        case 'sturdy':
          if (parts.length > 1) {
            final turns = int.tryParse(parts[1]) ?? 1;
            if (isAllTarget || faToAll) {
              for (final enemy in enemyTargets) {
                enemy.sturdy += turns;
              }
            } else if (target != null) {
              (target as Entity).sturdy += turns;
            } else {
              player.sturdy += turns;
            }
          }
          break;

        case 'self_damage':
          if (parts.length > 1) {
            final value = int.tryParse(parts[1]) ?? 1;
            // 修复：自损不应该受算力加成，直接扣除生命值
            player.hp = max(0, player.hp - value);
            anim.showDamage(player, value);
            _playHitSound();
            GameState.playerHp = player.hp;
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
              player.hp = min(player.hp, player.maxHp);
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

    if (energy < card.cost) {
      // 显示带宽不足提示
      _showStatusTip("带宽不足，无法使用该卡牌", Colors.redAccent);
      return;
    }

    energy -= card.cost;
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

    // 关键区域：血液职业被动【生命回收】
    if (characterData.characterClass == CharacterClass.xueye) {
      player.hp = (player.hp + 1).clamp(0, player.maxHp);
      anim.showHeal(player, 1);
      GameState.playerHp = player.hp;
      
      // 触发血液脉冲特效
      final ctx = context;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null) {
        final center = box.size.center(Offset.zero);
        anim.playRoleEffect(CharacterClass.xueye, center);
      }
    }

    // 关键区域：浪潮职业被动【涌动】—— 手牌为空时恢复宽带并摸牌
    if (characterData.characterClass == CharacterClass.langchao && hand.isEmpty) {
      energy = (energy + 2).clamp(0, 99);
      drawCards(2);
      _showStatusTip("【涌动】宽带回收 +2，下行摸牌 +2", const Color(0xFF4DCCFF));
      
      // 触发海浪线条特效
      final ctx = context;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null) {
        final center = box.size.center(Offset.zero);
        anim.playRoleEffect(CharacterClass.langchao, center);
      }
    }

    // 关键区域：几何职业被动【结构链路】—— 连续使用同类别卡牌获得宽带并摸牌
    if (characterData.characterClass == CharacterClass.jihe) {
      if (_lastUsedSuite != null && card.suite == _lastUsedSuite) {
        energy = (energy + 1).clamp(0, 99);
        drawCards(1);
        _showStatusTip("【结构链路】带宽回收 +1，数据读取 +1", const Color(0xFF00FF00));
        
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
      _showStatusTip("【稳态增压】临时算力 +5", const Color(0xFF6CE4FF));
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
            // 每损失 8 点生命值增加 1 点算力
            final lostHp = attacker.maxHp - attacker.hp;
           effectiveStrength += (lostHp ~/ 8);
         }
         
         finalDamage += effectiveStrength;
          if (attacker == player && characterData.characterClass == CharacterClass.jianren &&
              activePrograms.any((e) => e.hp > 0 && e.block <= 0)) {
            finalDamage = (finalDamage * 1.24).ceilToDouble();
          }
         
         // 虚弱状态：输出降低 25%
        if (attacker.weak > 0) {
          for (int i = 0; i < attacker.weak; i++) {
            finalDamage *= 0.75;
          }
        }
       }
       
       // 关键区域：受击者状态影响
       if (target.vulnerable > 0) {
         finalDamage *= (1.0 + 0.1 * target.vulnerable);
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
        }
        if (target.block == 0 && absorbed > 0) {
          anim.playShieldBreak(target);
          if (identical(target, player) && characterData.characterClass == CharacterClass.yingshi) {
            player.tempStrength += 16;
          }
        }
      }
      
      if (remaining > 0) {
      final beforeHp = target.hp;
      target.hp = max(0, target.hp - remaining);
      if (identical(target, player) && characterData.characterClass == CharacterClass.yingshi) {
        final gain = (max(0, beforeHp - target.hp) ~/ 5);
        if (gain > 0) player.tempStrength += gain;
      }
      
      // 关键区域：记录玩家受损状态（用于影蚀被动等）
      if (identical(target, player)) {
        _playerTookDamageThisTurn = true;
      }

      anim.showDamage(target, remaining);
      _playHitSound();
      GameStatistics.totalDamageDealt += remaining;
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

    // 每周期开始时重置带宽（能量）为固定值
    energy = 3;

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
    _playerTookDamageThisTurn = false; // 重置受损记录

    // 同步阶段开始时自动抽牌：随机获取数据包
    _randomDrawCards(bonus: drawBonus);
    hasDrawnCards = true;
    _rollSystemIntents(isTurnStart: true);

    setState(() {});
  }

  /// 随机抽牌逻辑：随机抽取随机张牌
  void _randomDrawCards({int bonus = 0}) {
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
            characterData.minDrawPerTurn +
            bonus;
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
    for (final program in activePrograms) {
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
          default:
            await _systemAttackPlayer(program);
            break;
        }
        program.intent = null;
        program.intentValue = 0;
        
        // 关键区域：怪物状态衰减
        if (program.vulnerable > 0) program.vulnerable--;
        if (program.weak > 0) program.weak--;
        if (program.sturdy > 0) program.sturdy--;
        
        // 关键区域：每个怪物行动完后更新UI
        setState(() {});
        
        // 检查玩家是否死亡
        if (player.hp <= 0) break;
      }
    }

    if (characterData.characterClass == CharacterClass.yanxin) {
      for (final program in activePrograms) {
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
    final random = Random();
    int totalDamage =
        predicted ??
        (program.baseDamage + (turnCount ~/ 3) + random.nextInt(3));
    // 关键区域：怪物攻击动画
    anim.playAttack(program, player);

    // 等待攻击动画冲击点
    await Future.delayed(const Duration(milliseconds: 300));
    _applyDamage(program, player, totalDamage);
    
    // 等待动画收回
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// 怪物恢复生命值
  void _systemHeal(Entity program, {int? amount}) {
    final random = Random();
    final healAmount = amount ?? (random.nextInt(5) + 3);
    program.hp = (program.hp + healAmount).clamp(0, program.maxHp);

    anim.showHeal(program, healAmount);
  }

  void _systemDefend(Entity program, {int? value}) {
    final random = Random();
    final v = value ?? (3 + (turnCount ~/ 3) + random.nextInt(4));
    program.block += v;
    anim.showBlockGain(program, v);
  }

  void _rollSystemIntents({bool isTurnStart = false}) {
    final random = Random();
    for (final m in activePrograms) {
      if (m.hp <= 0) {
        m.intent = null;
        m.intentValue = 0;
        continue;
      }

      // 如果不是回合开始，只有30%的概率改变意图
      if (!isTurnStart && m.intent != null) {
        if (random.nextDouble() > 0.3) {
          continue; // 保持原有意图
        }
      }

      final lowHp = m.hp < m.maxHp * 0.3;
      final p = random.nextDouble();
      if (lowHp && p < 0.4) {
        m.intent = SystemIntent.repair;
        m.intentValue = random.nextInt(5) + 3;
      } else if (p < 0.25) {
        m.intent = SystemIntent.encrypt;
        m.intentValue = 3 + (turnCount ~/ 3) + random.nextInt(4);
      } else {
        m.intent = SystemIntent.impact;
        double dmg = (m.baseDamage + (turnCount ~/ 3) + random.nextInt(3)).toDouble();
        
        // 考虑怪物的算力和虚弱
        dmg += m.strength;
        if (m.weak > 0) dmg *= 0.75;
        
        // 考虑玩家的脆弱和诅咒
        if (player.vulnerable > 0) dmg *= 1.5;
        dmg += player.curse * 2;
        
        m.intentValue = dmg.floor();
      }
    }
  }

  /// 检查带宽耗尽自动进入弃牌阶段
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
        _victoryRecorded = true;
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
        final shouldExit = await _onWillPopConfirm();
        if (shouldExit && context.mounted) {
          // 返回到开始页面（根路由）
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        body: AnimatedBuilder(
            animation: anim,
            builder:
                (context, _) => Stack(
                  children: [
                  // 关键区域：全域背景美化 - 动态扫描线与网格
                  Positioned.fill(
                    child: _BattleBackground(
                      pulses: anim.gridPulses,
                      gridColor: (() {
                        final hasBloodGlow = anim.roleEffects.any((e) => e.role == CharacterClass.xueye);
                        if (hasBloodGlow) return const Color(0xFFFF4D4D);
                        final isJianrenBoost = (characterData.characterClass == CharacterClass.jianren &&
                          activePrograms.any((e) => e.hp > 0 && e.block <= 0));
                        return isJianrenBoost ? const Color(0xFFFFD700) : const Color(0xFF6CE4FF);
                      })(),
                    ),
                  ),
                  if (characterData.characterClass == CharacterClass.langchao)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _WaveIdlePainter(),
                        ),
                      ),
                    ),
                  if (anim.fireOverlayActive)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _FireOverlayPainter(anim.fireOverlayStart!),
                        ),
                      ),
                    ),
                  // 关键区域：角色专属特效绘制层（作用于背景之上，UI之下）
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: RoleEffectPainter(anim.roleEffects),
                      ),
                    ),
                  ),
                  // 根据屏幕方向选择不同布局
                  isLandscape ? _landscapeLayout() : _portraitLayout(),
                  // 弃牌阶段：显示卡牌选择覆盖层
                  if (gamePhase == GamePhase.discardPhase && isDiscardPhase)
                    _bottomDiscardOverlay(),
                  // 同步阶段：显示进入弃牌按钮
                  if (gamePhase == GamePhase.syncPhase &&
                      hasDrawnCards &&
                      !isDiscardPhase)
                    _bottomDiscardOverlay(),
                  _attackGroup(AttackEffectType.laser),
                  _attackGroup(AttackEffectType.slash),
                  _attackGroup(AttackEffectType.explosion),
                  _attackGroup(AttackEffectType.inject),
                  _attackGroup(AttackEffectType.impact),
                  ...anim.motions.map(_cardMotionWidget),
                  ...anim.blockPopups.map(_blockDamagePopup),
                  ...anim.shieldBreaks.map(_shieldBreakEffect),
                  ...anim.popups.map(_damagePopup),
                  ...anim.blockGains.map(_blockGainPopup),
                  ...anim.healPopups.map(_healPopup),
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
                      child: _buffInfoPanel(),
                    ),
                  if (_interactionLocked)
                    Positioned.fill(
                      child: AbsorbPointer(
                        absorbing: true,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  if (anim.isScreenOverloaded) _screenOverloadOverlay(),
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
    return Stack(
      children: [
        // 内容层
        Column(
          children: [
            _topBar(), // 顶部状态栏
            _battleField(), // 怪物战斗区域
            Expanded(child: _handArea()), // 手牌区域
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
              const Color(0xFF6CE4FF),
              isDrawPile: true,
              onTap: () => _showCardListDialog("待载入指令 (抽牌堆)", drawPile, const Color(0xFF6CE4FF)),
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
              onTap: () => _showCardListDialog("已执行指令 (弃牌堆)", discardPile, const Color(0xFFFF5A5A)),
            ),
          ),
        ),
      ],
    );
  }

  // 横屏布局：左侧怪物区域 -> 中间手牌区域 -> 右侧顶部状态栏和牌堆区域
  Widget _landscapeLayout() {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(child: _battleField()), // 怪物战斗区域
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _topBar(),
                  Expanded(child: _handArea()),
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
            const Color(0xFF6CE4FF),
            isDrawPile: true,
            onTap: () => _showCardListDialog("待载入指令 (抽牌堆)", drawPile, const Color(0xFF6CE4FF)),
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
            onTap: () => _showCardListDialog("已执行指令 (弃牌堆)", discardPile, const Color(0xFFFF5A5A)),
          ),
        ),
      ],
    );
  }

  // 游戏状态提示组件
  Widget _statusTipWidget() {
    final color = _statusTipColor ?? Colors.redAccent;
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F16).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.8), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 内部扫描线
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: CyberScanline(color: color.withValues(alpha: 0.1)),
                ),
              ),
              // 装饰边角
              Positioned.fill(
                child: CustomPaint(
                  painter: CyberCornerPainter(color: color.withValues(alpha: 0.5)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "SYSTEM_ALERT",
                    style: TextStyle(
                      color: color.withValues(alpha: 0.5),
                      fontSize: 9,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusTip!,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 关键区域：顶部HUD（SafeArea避免状态栏遮挡）
  Widget _cyberHpBar({
    required int current,
    required int maxHp,
    required double width,
    double height = 20,
    Color color = const Color(0xFF6CE4FF),
    String label = "ITG",
  }) {
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
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isLowHp ? Colors.red.withValues(alpha: 0.5) : color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: Stack(
              children: [
                // 动态背景斜纹
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HpBarBackgroundPainter(color: color.withValues(alpha: 0.08)),
                  ),
                ),
                // 进度条主体
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: percent, end: percent),
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
                              color.withValues(alpha: 0.4),
                              color.withValues(alpha: 0.8),
                              color,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 进度条内部扫描光
                            CyberScanline(color: Colors.white.withValues(alpha: 0.15)),
                            // 右侧发光线
                            Positioned(
                              top: 0,
                              right: 0,
                              bottom: 0,
                              width: 2,
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.4),
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
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            builder: (context, val, child) {
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red.withValues(alpha: (0.4 * (0.3 + 0.7 * sin(val * pi))).clamp(0.0, 1.0)),
                    width: 1.5,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isLowHp ? Colors.red : color.withValues(alpha: 0.9),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      "$current/$maxHp",
                      style: TextStyle(
                        color: isLowHp ? Colors.red : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 4),
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

  Widget _topBar() {
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
              color: ((characterData.characterClass == CharacterClass.jianren &&
                      activePrograms.any((e) => e.hp > 0 && e.block <= 0))
                  ? const Color(0xFFFFD700)
                  : const Color(0xFF6CE4FF)).withValues(alpha: 0.4),
              width: 1.6,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: ((characterData.characterClass == CharacterClass.jianren &&
                      activePrograms.any((e) => e.hp > 0 && e.block <= 0))
                  ? const Color(0xFFFFD700)
                  : const Color(0xFF6CE4FF)).withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 元数据标签
            Row(
              children: [
                Text(
                  "// SYSTEM_INTEGRITY_LINK",
                  style: TextStyle(
                    color: ((characterData.characterClass == CharacterClass.jianren &&
                            activePrograms.any((e) => e.hp > 0 && e.block <= 0))
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF6CE4FF)).withValues(alpha: 0.6),
                    fontSize: 7,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Text(
                  "NODE: ${widget.levelId ?? 'UNKNOWN'}",
                  style: TextStyle(
                    color: ((characterData.characterClass == CharacterClass.jianren &&
                            activePrograms.any((e) => e.hp > 0 && e.block <= 0))
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF6CE4FF)).withValues(alpha: 0.6),
                    fontSize: 7,
                    letterSpacing: 1,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0F16),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: ((characterData.characterClass == CharacterClass.jianren &&
                                    activePrograms.any((e) => e.hp > 0 && e.block <= 0))
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF6CE4FF)).withValues(alpha: 0.75),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ((characterData.characterClass == CharacterClass.jianren &&
                                      activePrograms.any((e) => e.hp > 0 && e.block <= 0))
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF6CE4FF)).withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.map,
                          size: 16,
                          color: ((characterData.characterClass == CharacterClass.jianren &&
                                  activePrograms.any((e) => e.hp > 0 && e.block <= 0))
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF6CE4FF)),
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
                            label: "ITG",
                            color: ((characterData.characterClass == CharacterClass.jianren &&
                                    activePrograms.any((e) => e.hp > 0 && e.block <= 0))
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF6CE4FF)),
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
                      duration: const Duration(milliseconds: 400),
                      tween: Tween(begin: 1.2, end: 1.0),
                      builder: (context, scale, child) {
                        final bool hasBlock = player.block > 0;
                        final bool isGold = (characterData.characterClass == CharacterClass.jianren &&
                          activePrograms.any((e) => e.hp > 0 && e.block <= 0));
                        final Color blockColor = isGold
                            ? const Color(0xFFFFD700)
                            : (hasBlock ? const Color(0xFF6CE4FF) : const Color(0xFF2A4158));
                        
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              border: Border.all(
                                color: blockColor,
                                width: hasBlock ? 1.5 : 1,
                              ),
                              boxShadow: [
                                if (hasBlock)
                                  BoxShadow(
                                    color: blockColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: blockColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "FWL",
                                  style: TextStyle(
                                    color: blockColor.withValues(alpha: 0.7),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${player.block}",
                                  style: TextStyle(
                                    color: blockColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    shadows: [
                                      if (hasBlock)
                                        Shadow(color: blockColor.withValues(alpha: 0.5), blurRadius: 4),
                                    ],
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
                // 右侧：设置按钮
                IconButton(
                icon: Icon(
                  Icons.power_settings_new,
                  size: 18,
                  color: ((characterData.characterClass == CharacterClass.jianren &&
                          activePrograms.any((e) => e.hp > 0 && e.block <= 0))
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF8FA3C0)),
                ),
                onPressed: () async {
                  final shouldExit = await _onWillPopConfirm();
                  if (shouldExit && context.mounted) {
                    // 返回到开始页面（根路由）
                    Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
      bottom: 20, // 稍微上移一点，避免被系统条遮挡
      child: Center(
        child: _buildSciFiButton(
          heroTag: 'main_action_button',
          text: "同步当前周期",
          onTap: startDiscardPhase,
          color: const Color(0xFF6CE4FF),
          icon: Icons.power_settings_new,
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
    return _playerWidget(player);
  }

  Widget _playerWidget(Entity e, {bool isHighlighted = false}) {
    final isGlitching = anim.glitching.contains(e);
    final isProtecting = anim.protecting.contains(e);
    final isBouncing = anim.bouncing.contains(e);

    // 内部构建核心内容，完全不带任何 Key
    Widget buildCore() {
      return Container(
        width: 70,
        height: 85,
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFF102A22) : const Color(0xFF0A0F16),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isHighlighted 
                ? const Color(0xFF6CE4FF)
                : (isProtecting 
                    ? const Color(0xFF6CE4FF) 
                    : const Color(0xFF6CE4FF).withValues(alpha: 0.4)),
            width: (isProtecting || isHighlighted) ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isProtecting || isHighlighted)
                  ? const Color(0xFF6CE4FF).withValues(alpha: 0.5)
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
                    color: (isHighlighted ? const Color(0xFF6CE4FF) : const Color(0xFF6CE4FF).withValues(alpha: 0.2)),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.1.clamp(0.0, 1.0),
                child: CyberScanline(color: const Color(0xFF6CE4FF)),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, val, child) {
                      return Transform.scale(
                        scale: isHighlighted ? 1.1 : val,
                        child: Icon(
                          Icons.person,
                          size: 42,
                          color: isHighlighted 
                              ? const Color(0xFF6CE4FF)
                              : const Color(0xFF6CE4FF).withValues(alpha: 0.8),
                          shadows: [
                            Shadow(
                              color: const Color(0xFF6CE4FF).withValues(alpha: 0.5),
                              blurRadius: isHighlighted ? 12 : 8,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  _statusEffectsBar(e),
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
                      color: const Color(0xFF6CE4FF).withValues(alpha: (1.0 - (val - 1.0) * 3).clamp(0.0, 1.0)),
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

        // 基础空闲呼吸效果
        final breathTime = DateTime.now().millisecondsSinceEpoch / 1500.0;
        scale += sin(breathTime * 2) * 0.015;

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
    return AnimatedOpacity(
      key: e.key,
      opacity: 1.0,
      duration: const Duration(milliseconds: 100),
      child: box,
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
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 内部动态扫描线
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: CyberScanline(color: color.withValues(alpha: 0.2)),
              ),
            ),
            // 装饰边角
            Positioned.fill(
              child: CustomPaint(
                painter: CyberCornerPainter(color: color.withValues(alpha: 0.4)),
              ),
            ),
            // 按钮内容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 减小水平内边距，原为 20
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
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
  Widget _resultOverlay() {
    final color = isVictory ? const Color(0xFF6CE4FF) : const Color(0xFFFF4444);
    
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
                    if (isVictory) _victoryParticles(t),
                    
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
                            // 内部装饰：扫描线
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CyberScanline(color: color.withValues(alpha: 0.1)),
                              ),
                            ),
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
                                  _victoryTitle(t)
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
                                _gameStatisticsWidget(),
                                const SizedBox(height: 28),
                                
                                // 按钮区域
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (isVictory) ...[
                                      _overlayButton(
                                        Icons.map,
                                        GameProgress.isCurrentNationFinished() ? "同步完成：查看拓扑图" : "拓扑网络",
                                        () {
                                          // 胜利后，标记当前关卡已击败
                                          if (widget.levelId != null) {
                                            GameProgress.markDefeated(widget.levelId!);
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
                                        color: const Color(0xFF6CE4FF),
                                        heroTag: 'main_action_button',
                                      ),
                                    ] else ...[
                                      _overlayButton(
                                        Icons.refresh,
                                        "重载系统",
                                        () {
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
                  child: CustomPaint(painter: ScanlineJitterPainter(strength: 2.0 * (1.0 - t))),
                ),
              ],
            );
          },
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
  Widget _victoryTitle(double t) {
    return Column(
      children: [
        Text(
          'DATA_SYNC_COMPLETE',
          style: TextStyle(
            color: const Color(0xFF6CE4FF).withValues(alpha: 0.5),
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
                colors: const [Color(0xFF6CE4FF), Color(0xFFE1E9FF), Color(0xFF6CE4FF)],
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
                  Shadow(color: const Color(0xFF6CE4FF).withValues(alpha: 0.3), blurRadius: 10),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 游戏统计信息组件
  Widget _gameStatisticsWidget() {
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
                color: const Color(0xFF6CE4FF),
              ),
              const SizedBox(width: 8),
              const Text(
                '渗透数据分析 / ANALYZING...',
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
          _statRow('数据同步周期 (回合)', '${GameStatistics.totalTurns}', const Color(0xFFE1E9FF)),
          _statRow('调用指令集 (出牌)', '${GameStatistics.totalCardsUsed}', const Color(0xFF6CE4FF)),
          _statRow('数据破坏值 (伤害)', '${GameStatistics.totalDamageDealt}', const Color(0xFFFF6A6A)),
          _statRow('防御拦截值 (护盾)', '${GameStatistics.totalDamageBlocked}', const Color(0xFF5AD1FF)),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
    );
  }

  // 关键区域：胜利粒子效果（星光）
  // 关键区域：胜利后的粒子飘散效果 - 动态增强版
  Widget _victoryParticles(double t) {
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
                color: index % 2 == 0 ? Colors.amberAccent : Colors.cyanAccent,
                size: 14 + 10 * (1 - t),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<bool> _onWillPopConfirm() async {
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
                      child: CyberScanline(color: const Color(0x11FF6A6A)),
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
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6A6A), size: 20),
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
                        '即将终止当前的数据尖塔渗透任务，未同步的数据流将会丢失。是否确认断开物理接入？',
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
                          _dialogButton(
                            ctx, 
                            '维持接入', 
                            const Color(0xFF6CE4FF), 
                            () => Navigator.pop(ctx, false)
                          ),
                          const SizedBox(width: 16),
                          _dialogButton(
                            ctx, 
                            '确认断开', 
                            const Color(0xFFFF6A6A), 
                            () => Navigator.pop(ctx, true)
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

  Widget _dialogButton(BuildContext context, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
      ),
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

        // 内部构建核心内容，完全不带 Key
        Widget buildCore() {
          final coreColor = isDead 
              ? const Color(0xFFFF4444) 
              : (isHighlighted ? const Color(0xFF6CE4FF) : const Color(0xFF2A4158));

          return Container(
            width: 90 * s, 
            height: 110 * s,
            decoration: BoxDecoration(
              color:
                  isDead
                      ? Colors.grey.shade900.withValues(alpha: 0.5)
                      : (isHighlighted
                          ? const Color(0xFF2A1010)
                          : (isBeingDragged
                              ? const Color(0xFF101722)
                              : const Color(0xFF0A0F16))),
              borderRadius: BorderRadius.circular(6),
              border:
                  isHighlighted
                      ? Border.all(color: const Color(0xFF6CE4FF), width: 2.0)
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
                          color: const Color(0xFF6CE4FF).withValues(alpha: 0.3),
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
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.9, end: 1.0),
                    duration: const Duration(seconds: 3),
                    curve: Curves.easeInOut,
                    builder: (context, val, child) {
                      return Transform.scale(
                        scale: val,
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
                      );
                    },
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

            // 基础空闲悬浮动画 (idle floating)
            final idleTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
            dy += sin(idleTime * 2 + program.id.hashCode % 10) * 3;

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
        String? intentValueText;
         IconData? intentIcon;
         Color? intentColor;
         switch (program.intent) {
          case SystemIntent.impact:
            intentValueText = "${program.intentValue}";
            intentIcon = Icons.bolt;
            intentColor = Colors.redAccent;
            break;
          case SystemIntent.encrypt:
            intentValueText = "${program.intentValue}";
            intentIcon = Icons.shield;
            intentColor = Colors.cyanAccent;
            break;
          case SystemIntent.repair:
            intentValueText = "${program.intentValue}";
            intentIcon = Icons.auto_fix_high;
            intentColor = Colors.greenAccent;
            break;
          default:
            intentValueText = null;
            intentIcon = null;
            intentColor = null;
        }

        return AnimatedOpacity(
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
              if (intentIcon != null)
                Positioned(
                  top: -65 * s,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0F16).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: (intentColor ?? const Color(0xFF6CE4FF)).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          intentIcon,
                          size: 16 * s,
                          color: intentColor,
                        ),
                        if (intentValueText != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            intentValueText,
                            style: TextStyle(
                              fontSize: (14 * s).clamp(10, 14),
                              fontWeight: FontWeight.w900,
                              color: intentColor,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
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
                      label: "SYS",
                      color: const Color(0xFFE1E9FF), // 敌方使用银白色
                    ),
                    if (program.block > 0) ...[
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        key: ValueKey("monster_block_${program.block}"),
                        tween: Tween(begin: 1.2, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, val, child) {
                          const Color blockColor = Color(0xFF6CE4FF);
                          return Transform.scale(
                            scale: val,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
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
                                      color: const Color(0xFF6CE4FF),
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
                          color: Colors.black.withValues(alpha: 0.3.clamp(0.0, 1.0)),
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

  Widget _pileWidget(IconData icon, int count, Color color, {required bool isDrawPile, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
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
            // 内部动态扫描线
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CyberScanline(color: color.withValues(alpha: 0.3)),
              ),
            ),
            // 装饰边角
            Positioned.fill(
              child: CustomPaint(
                painter: CyberCornerPainter(color: color.withValues(alpha: 0.4)),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
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

  /// 带宽核心组件：科技感十足的数字仪表
  Widget _energyCoreWidget() {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 核心外框：简化为一个统一的科幻容器
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E14).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFF6CE4FF).withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6CE4FF).withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // 内部扫描线
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: const CyberScanline(color: Color(0x336CE4FF)),
                  ),
                ),
                // 装饰边角
                Positioned.fill(
                  child: CustomPaint(
                    painter: CyberCornerPainter(color: const Color(0xFF6CE4FF).withValues(alpha: 0.4)),
                  ),
                ),
              ],
            ),
          ),
          // 内部内容
          TweenAnimationBuilder<double>(
            key: ValueKey("energy_$energy"),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            tween: Tween(begin: 1.3, end: 1.0),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "BANDWIDTH",
                      style: TextStyle(
                        color: const Color(0xFF6CE4FF).withValues(alpha: (0.5 + (scale - 1.0) * 2).clamp(0.0, 1.0)),
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: const Color(0xFF6CE4FF).withValues(alpha: (0.8 + (scale - 1.0) * 0.5).clamp(0.0, 1.0)),
                          size: 14,
                        ),
                        Text(
                          "$energy",
                          style: TextStyle(
                            color: const Color(0xFF6CE4FF),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF6CE4FF).withValues(alpha: 0.8),
                                blurRadius: 10 * scale,
                              ),
                              if (scale > 1.0)
                                Shadow(
                                  color: const Color(0xFF6CE4FF).withValues(alpha: 0.3),
                                  blurRadius: 20 * scale,
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

  Widget _handArea() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // 手牌上方的判定区
        if (gamePhase != GamePhase.discardPhase)
          Positioned(
            left: 0,
            right: 0,
            bottom: 140 + (hand.length <= 6 ? 0 : (hand.length > 10 ? 140 : 70)),
            child: _judgementArea(),
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
              ? _discardPhaseView()
              : _fanHandView(),
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
  Widget _buffInfoPanel() {
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
                  color: const Color(0xFF6CE4FF).withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6CE4FF).withValues(alpha: 0.2),
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
                            color: const Color(0xFF6CE4FF),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _activeBuffName!,
                            style: const TextStyle(
                              color: Color(0xFF6CE4FF),
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
  Widget _handCountWidget() {
    return Container(
      width: 50,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E14).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF6CE4FF).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: const CyberScanline(color: Color(0x226CE4FF)),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: CyberCornerPainter(color: const Color(0x446CE4FF)),
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
                color: const Color(0xFF6CE4FF).withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                "${hand.length}",
                style: const TextStyle(
                  color: Color(0xFF6CE4FF),
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
  Widget _fanHandView() {
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
              Positioned(left: 10, top: 10, child: _energyCoreWidget()),
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

        // 1. 能量核心：固定在左上角
        children.add(
          Positioned(
            left: 10,
            top: 10,
            child: _energyCoreWidget(),
          ),
        );
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
            top: max(0.0, anchorTopY - 32),
            child: Center(child: _handCountWidget()),
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
  Widget _discardPhaseView() {
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
                    Positioned(left: 10, top: 10, child: _energyCoreWidget()),
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

              // 1. 能量核心
              children.add(
                Positioned(
                  left: 10,
                  top: 10,
                  child: _energyCoreWidget(),
                ),
              );
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
                  top: max(0.0, baseY - 28),
                  child: Center(child: _handCountWidget()),
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
            "锁定核心数据流，其余数据将执行清除程序",
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
                  case CardSuite.classic: return const Color(0xFF6CE4FF);
                  case CardSuite.overload: return const Color(0xFFFF4444);
                  case CardSuite.secure: return const Color(0xFFC3A6FF);
                  case CardSuite.industrial: return const Color(0xFFFFB344);
                  case CardSuite.quantum: return const Color(0xFFE26CFF);
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
                    child: CustomPaint(painter: GridPainter(scanColor)),
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
                  case CardSuite.classic: return const Color(0xFF6CE4FF);
                  case CardSuite.overload: return const Color(0xFFFF4444);
                  case CardSuite.secure: return const Color(0xFFC3A6FF);
                  case CardSuite.industrial: return const Color(0xFFFFB344);
                  case CardSuite.quantum: return const Color(0xFFE26CFF);
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
                    child: CustomPaint(painter: GridPainter(scanColor)),
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

  /// 构建卡牌描述文本，智能识别正面/负面效果并着色
  Widget _buildCardDescription(CardData c, Color highlightColor) {
    final String text = c.description ?? "";
    if (text.isEmpty) return const SizedBox.shrink();

    // 关键词分类
    const buffKeywords = {'防火墙加固', '算力', '系统修复', '能量', '能量点', '数据包', '带宽'};
    const debuffKeywords = {'虚弱', '脆弱', '漏洞暴露', '恶意代码'};
    const damageKeywords = {'冲击', '自损', '受损'};

    // 匹配数字和关键效果词汇
    final regex = RegExp(r'(\d+)|(冲击|防火墙加固|数据包|算力|虚弱|脆弱|恶意代码|自损|系统修复|能量|能量点|漏洞暴露|受损|带宽)');
    final List<TextSpan> spans = [];
    int lastMatchEnd = 0;
    final double fontScale = text.length > 28 ? (28.0 / text.length).clamp(0.7, 1.0) : 1.0;

    for (final match in regex.allMatches(text)) {
      // 1. 添加普通文本（淡化）
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 8 * fontScale),
        ));
      }

      final isNumber = match.group(1) != null;
      final matchText = match.group(0)!;
      
      // 2. 智能判定该项是“好”还是“坏”
      bool isBadEffect = false;
      
      // 确定该项关联的关键字和目标
      String associatedKeyword = "";
      if (isNumber) {
        // 数字寻找最近的关键字（前后探测）
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

      // 确定目标
      CardTarget target = c.target;
      if (associatedKeyword == "自损" || associatedKeyword == "受损") {
        target = CardTarget.self;
      }

      // 应用判定矩阵
      if (damageKeywords.contains(associatedKeyword)) {
        // 伤害：对自己是坏，对敌人是好
        isBadEffect = (target == CardTarget.self);
      } else if (buffKeywords.contains(associatedKeyword)) {
        // Buff：对自己是好，对敌人是坏
        isBadEffect = (target != CardTarget.self);
      } else if (debuffKeywords.contains(associatedKeyword)) {
        // Debuff：对自己是坏，对敌人是好
        isBadEffect = (target == CardTarget.self);
      }

      // 3. 添加高亮项
      Color displayColor = isBadEffect ? const Color(0xFFFF4444) : (isNumber ? Colors.white : highlightColor);
      
      spans.add(TextSpan(
        text: matchText,
        style: TextStyle(
          color: displayColor,
          fontWeight: (isNumber || isBadEffect) ? FontWeight.w900 : FontWeight.bold,
          fontSize: (isNumber ? 10 : 9) * fontScale,
          shadows: [
            Shadow(color: displayColor.withValues(alpha: 0.6), blurRadius: 4),
          ],
        ),
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 8 * fontScale),
      ));
    }

    return RichText(
      text: TextSpan(children: spans, style: const TextStyle(fontFamily: 'monospace', height: 1.3)),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _cardWidget(
    CardData c, {
    bool dragging = false,
    bool showCompleteAnimation = false,
  }) {
    // 关键区域：根据卡牌套装(Suite)确定视觉风格
    Color getSuiteColor() {
      switch (c.suite) {
        case CardSuite.classic: return const Color(0xFF6CE4FF); // 经典霓虹青
        case CardSuite.overload: return const Color(0xFFFF4444); // 红色过载
        case CardSuite.secure: return const Color(0xFFC3A6FF); // 淡紫色
        case CardSuite.industrial: return const Color(0xFFFFB344); // 工业机械橙
        case CardSuite.quantum: return const Color(0xFFE26CFF); // 量子虚空紫
      }
    }

    Color getRarityColor() {
        switch (c.level) {
          case 1: return const Color(0xFF44FF44); // 绿色 (普通) - 已对换
          case 2: return const Color(0xFF6CE4FF); // 蓝绿色 (优秀) - 已对换
          case 3: return const Color(0xFFE26CFF); // 紫色 (稀有)
        case 4: return const Color(0xFFFFD700); // 金色 (史诗)
        case 5: return const Color(0xFFFF4444); // 红色 (传说)
        default: return Colors.white70;
      }
    }

    final suiteColor = getSuiteColor();
    final rarityColor = getRarityColor();
    
    // 背景色微调：不同套装背景略有差异
    Color getCardBgColor() {
      switch (c.suite) {
        case CardSuite.overload: return const Color(0xFF1A0A0A);
        case CardSuite.secure: return const Color(0xFF1A0A1A);
        case CardSuite.industrial: return const Color(0xFF1A140A);
        case CardSuite.quantum: return const Color(0xFF140A1A);
        case CardSuite.classic: return const Color(0xFF101722);
      }
    }
    
    final cardBgColor = getCardBgColor().withValues(alpha: 0.9);
    
    Widget cardBody(double scale) {
      return Transform.scale(
        scale: scale,
        child: Container(
          width: 84,
          height: 112,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: dragging ? Colors.white : suiteColor.withValues(alpha: 0.6),
              width: dragging ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: suiteColor.withValues(alpha: dragging ? 0.5 : 0.2),
                blurRadius: dragging ? 15 : 8,
                spreadRadius: dragging ? 2 : 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                // 1. 背景纹理：不同套装使用不同画笔
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
                      isGlitch: c.suite == CardSuite.overload, // 过载套装带故障效果
                    ),
                  ),
                ),
                // 3. 科技感边角装饰
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: CyberCornerPainter(color: suiteColor.withValues(alpha: 0.15)),
                    ),
                  ),
                ),
                // 4. 内容层
                Padding(
                  padding: const EdgeInsets.all(6),
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
                                final base = 9.0;
                                final shrink = name.length > 4 ? (base - (name.length - 4) * 0.5) : base;
                                final titleFont = shrink.clamp(6.5, base);
                                return Text(
                                  name,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                  style: TextStyle(
                                    fontSize: titleFont,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    letterSpacing: 0.5,
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
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF05060A),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: suiteColor.withValues(alpha: 0.5), width: 0.5),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getSuiteIcon(c.suite),
                                  size: 8,
                                  color: suiteColor,
                                ),
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
                      // 标题下方的彩色横线：使用卡组风格颜色
                      Container(
                        width: double.infinity,
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              suiteColor,
                              suiteColor.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 描述文字
                      Expanded(
                        child: _buildCardDescription(c, suiteColor),
                      ),
                      // 底部标识
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Lv${c.level}",
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                              color: rarityColor.withValues(alpha: 0.9),
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
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
        ),
      );
    }

    if (showCompleteAnimation) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 1.5, end: 1.0),
        curve: Curves.bounceOut,
        builder: (context, scale, child) => cardBody(scale),
      );
    } else {
      return cardBody(1.0);
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

  // 更加科幻的微型目标图标
  Widget _smallTargetIcon(CardTarget target, Color color) {
    IconData icon;
    switch (target) {
      case CardTarget.enemy:
        icon = Icons.gps_fixed;
        break;
      case CardTarget.self:
        icon = Icons.shield;
        break;
      case CardTarget.all:
        icon = Icons.grain;
        break;
    }
    return Icon(icon, size: 10, color: color.withValues(alpha: 0.6));
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

  // 1. 物理冲击特效 (改为能量波视觉效果)
  Widget _impactEffect(AttackEffect e) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) {
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        final scale = 0.5 + t * 2.0;
        return Stack(
          children: [
            // 目标位置的冲击波
            Positioned(
              left: e.end.dx + 50 - (40 * scale),
              top: e.end.dy + 60 - (40 * scale),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 80 * scale,
                  height: 80 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6CE4FF).withValues(alpha: opacity),
                      width: 4 * (1 - t),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6CE4FF).withValues(alpha: opacity * 0.5),
                        blurRadius: 20 * t,
                        spreadRadius: 5 * t,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 2. 激光射线特效
  Widget _laserEffect(AttackEffect e) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AnimDurations.laser,
      builder: (_, t, __) {
        final opacity = t < 0.2 ? t / 0.2 : (t < 0.8 ? 1.0 : 1.0 - (t - 0.8) / 0.2);
        final width = t < 0.3 ? t / 0.3 * 8.0 : (1.0 - (t - 0.3) / 0.7) * 8.0;
        
        return Stack(
          children: [
            CustomPaint(
              painter: LaserPainter(
                start: e.start + const Offset(40, 48),
                end: e.end + const Offset(50, 60),
                progress: t,
                color: EffectColors.laserPrimary,
                width: width,
                opacity: opacity,
              ),
            ),
            // 目标处的冲击光圈
            if (t > 0.2 && t < 0.8)
              Positioned(
                left: e.end.dx + 50 - 30,
                top: e.end.dy + 60 - 30,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 200),
                  builder: (_, v, __) => Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF6CE4FF).withValues(alpha: 1.0 - v), width: 2),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 3. 斩击特效
  Widget _slashEffect(AttackEffect e) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AnimDurations.slash,
      builder: (_, t, __) {
        return Stack(
          children: [
            // 斩击痕迹
            CustomPaint(
              painter: SlashPainter(
                center: e.end + const Offset(50, 60),
                progress: t,
                color: EffectColors.slashPrimary,
              ),
            ),
          ],
        );
      },
    );
  }

  // 4. 爆炸特效
  Widget _explosionEffect(AttackEffect e) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      builder: (_, t, __) {
        return Stack(
          children: [
            // 投掷物轨迹
            if (t < 0.4)
              Positioned(
                left: Offset.lerp(e.start, e.end, t / 0.4)!.dx + 40,
                top: Offset.lerp(e.start, e.end, t / 0.4)!.dy + 40,
                child: Transform.rotate(
                  angle: t * 10,
                  child: const Icon(Icons.brightness_high, color: Color(0xFFFF9500), size: 24),
                ),
              ),
            // 爆炸火花
            if (t >= 0.3)
              ...List.generate(12, (i) {
                final progress = ((t - 0.3) / 0.7).clamp(0.0, 1.0);
                if (progress <= 0 || progress >= 1) return const SizedBox();
                final angle = (i * 30) * pi / 180;
                final dist = progress * 80;
                return Positioned(
                  left: e.end.dx + 50 + cos(angle) * dist,
                  top: e.end.dy + 60 + sin(angle) * dist,
                  child: Opacity(
                    opacity: 1.0 - progress,
                    child: Container(
                      width: 8 * (1 - progress),
                      height: 8 * (1 - progress),
                      decoration: const BoxDecoration(color: Color(0xFFFF4444), shape: BoxShape.circle),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  // 5. 注入特效
  Widget _injectEffect(AttackEffect e) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (_, t, __) {
        return Stack(
          children: [
            // 注入流
            if (t < 0.6)
              ...List.generate(5, (i) {
                final delay = i * 0.1;
                final progress = ((t - delay) / 0.5).clamp(0.0, 1.0);
                if (progress <= 0 || progress >= 1) return const SizedBox();
                final pos = Offset.lerp(e.start + const Offset(40, 48), e.end + const Offset(50, 60), progress)!;
                return Positioned(
                  left: pos.dx,
                  top: pos.dy,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(color: Color(0xFF00FFCC), shape: BoxShape.circle),
                  ),
                );
              }),
            // 目标处的数据流上升
            if (t > 0.4)
              ...List.generate(3, (i) {
                final progress = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
                return Positioned(
                  left: e.end.dx + 30 + (i * 20),
                  top: e.end.dy + 80 - (progress * 60),
                  child: Opacity(
                    opacity: (1.0 - progress) * 0.7,
                    child: Text(
                      (i % 2 == 0 ? "101" : "011"),
                      style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _damagePopup(DamagePopup p) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AnimDurations.popup,
      curve: AnimCurves.fastOut,
      builder: (_, t, __) {
        final tt = t.clamp(0.0, 1.0);
        final dy = -64 * AnimCurves.gentleOut.transform(tt);
        final scale = tt < 0.15 ? 0.7 + tt * 2.2 : 1.15 - (tt - 0.15) * 0.2;
        final rot = (tt < 0.2 ? (tt - 0.1) * 0.12 : 0.0);
        final opacity = tt < 0.7 ? 1.0 : 1.0 - (tt - 0.7) / 0.3;

        return Positioned(
          left: p.pos.dx,
          top: p.pos.dy + dy,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: rot,
              child: Transform.scale(
                scale: scale.clamp(0.0, 1.6),
                child: Text(
                  "-${p.value}",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                    fontFamily: 'monospace',
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                      Shadow(color: Colors.redAccent, blurRadius: 16),
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

  // 关键区域：防火墙冲击弹窗
  Widget _blockDamagePopup(BlockPopup p) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AnimDurations.popup,
      curve: AnimCurves.gentleOut,
      builder: (_, t, __) {
        final tt = t.clamp(0.0, 1.0);
        final dy = -42 * AnimCurves.gentleOut.transform(tt);
        final opacity = tt < 0.75 ? 1.0 : 1.0 - (tt - 0.75) / 0.25;
        final scale = tt < 0.25 ? 0.85 + tt : 1.05 - (tt - 0.25) * 0.2;

        return Positioned(
          left: p.pos.dx,
          top: p.pos.dy + dy,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale.clamp(0.0, 1.4),
              child: Text(
                "-${p.value}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.cyanAccent,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4),
                    Shadow(color: Colors.cyanAccent, blurRadius: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _blockGainPopup(BlockGainPopup p) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AnimDurations.popup,
      curve: AnimCurves.gentleOut,
      builder: (_, t, __) {
        final tt = t.clamp(0.0, 1.0);
        final dy = -38 * AnimCurves.gentleOut.transform(tt);
        final opacity = tt < 0.8 ? 1.0 : 1.0 - (tt - 0.8) / 0.2;
        final scale = tt < 0.25 ? 0.7 + tt * 1.5 : 1.08 - (tt - 0.25) * 0.1;

        return Positioned(
          left: p.pos.dx,
          top: p.pos.dy + dy,
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: Transform.scale(
              scale: scale.clamp(0, 1.2),
              child: Text(
                "+${p.value}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.cyanAccent,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4),
                    Shadow(color: Colors.cyanAccent, blurRadius: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _healPopup(HealPopup p) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AnimDurations.popup,
      curve: AnimCurves.mediumOut,
      builder: (_, t, __) {
        final dy = -45 * AnimCurves.mediumOut.transform(t.clamp(0.0, 1.0));
        final opacity = t < 0.7 ? 1.0 : 1.0 - (t - 0.7) / 0.3;
        final scale = t < 0.3 ? 0.5 + t * 2 : 1.1;

        return Positioned(
          left: p.pos.dx,
          top: p.pos.dy + dy,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale.clamp(0.0, 1.3),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 20, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  Text(
                    "+${p.value}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                        Shadow(color: Colors.greenAccent, blurRadius: 10),
                      ],
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
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
        builder: (context, val, child) {
          final isHighlighted = _activeBuffName == tooltip;
          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28, minHeight: 22),
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isHighlighted 
                  ? color.withValues(alpha: 0.2) 
                  : const Color(0xFF0A0F16).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: isHighlighted ? color : color.withValues(alpha: 0.5), 
                width: isHighlighted ? 1.2 : 0.8
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: (isHighlighted ? 0.3 : 0.1 * val).clamp(0.0, 1.0)),
                  blurRadius: isHighlighted ? 8 : 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: val,
                  child: Icon(icon, size: 10, color: color),
                ),
                const SizedBox(width: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ));
        },
      ),
    );
  }

  Widget _statusEffectsBar(Entity e) {
    final effects = <Widget>[];

    final int normalStrength = e.strength;
    int bloodBonus = 0;

    if (e == player && characterData.characterClass == CharacterClass.xueye) {
      bloodBonus = (e.maxHp - e.hp) ~/ 8;
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
          "脆弱",
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
        _statusIcon(Icons.shield, "${e.sturdy}", Colors.cyanAccent, "坚固"),
      );
    }
    if (e.fire > 0) {
      effects.add(
        _statusIcon(Icons.local_fire_department, "${e.fire}", const Color(0xFFFF9500), "火焰"),
      );
    }

    if (effects.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 24,
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
      // 在目标位置产生一个冲击波效果（借用 DamagePopup 但值为 0）
      final p = DamagePopup(0, pos);
      anim.popups.add(p);
      anim.refresh();
      Future.delayed(const Duration(milliseconds: 800), () {
        anim.popups.remove(p);
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
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // 1. 背景层：模糊与网格
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0F16).withValues(alpha: 0.8),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // 2. 动态扫描线
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CyberScanline(color: color),
                    ),
                  ),
                  
                  // 3. 装饰性边角
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: CyberCornerPainter(color: color),
                      ),
                    ),
                  ),
                  
                  // 4. 内容层
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题栏
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "// DATA_STREAM_VISUALIZER",
                                  style: TextStyle(
                                    color: color.withValues(alpha: 0.5),
                                    fontSize: 10,
                                    letterSpacing: 2,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    fontSize: 22,
                                    shadows: [
                                      Shadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: color.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "ENTRIES: ${cards.length}",
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // 分割线
                        Container(
                          height: 1,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.8),
                                color.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // 卡牌列表
                        Expanded(
                          child: cards.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.wifi_off, color: color.withValues(alpha: 0.3), size: 48),
                                      const SizedBox(height: 16),
                                      Text(
                                        "当前数据链路为空",
                                        style: TextStyle(
                                          color: color.withValues(alpha: 0.5),
                                          fontSize: 18,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Theme(
                                  data: ThemeData.dark().copyWith(
                                    scrollbarTheme: ScrollbarThemeData(
                                      thumbColor: WidgetStateProperty.all(color.withValues(alpha: 0.5)),
                                      radius: const Radius.circular(10),
                                    ),
                                  ),
                                  child: GridView.builder(
                                    padding: const EdgeInsets.only(right: 8),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.72,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
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
                        
                        const SizedBox(height: 16),
                        
                        // 底部按钮
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                border: Border.all(color: color.withValues(alpha: 0.6)),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                "关闭会话 [ESC]",
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
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
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: anim1,
              curve: Curves.easeOutBack,
            ),
            child: child,
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
            painter: _GridPainter(pulses: pulses, gridColor: gridColor),
          ),
        ),
      ],
    );
  }
}

/// 背景网格绘制
class _GridPainter extends CustomPainter {
  final List<GridPulse> pulses;
  final Color gridColor;
  _GridPainter({required this.pulses, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    const spacing = 40.0;
    const maxRadius = 1000.0;
    final pulseDurationMs = AnimDurations.gridPulse.inMilliseconds;
    final isGold = gridColor.value == const Color(0xFFFFD700).value;
    final baseAlpha = isGold ? 0.05 : 0.02;
    final pulseAlpha = isGold ? 0.22 : 0.10;
    final ringAlpha = isGold ? 0.30 : 0.15;
    final baseStroke = isGold ? 1.4 : 1.0;
    final pulseStroke = isGold ? 2.0 : 1.5;
    final ringStroke = isGold ? 2.4 : 2.0;
    final ringBlur = isGold ? 16.0 : 10.0;

    // 绘制基础弱网格
    final basePaint = Paint()
      ..color = gridColor.withValues(alpha: baseAlpha)
      ..strokeWidth = baseStroke;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), basePaint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), basePaint);
    }

    // 绘制扩散脉冲效果
    for (final pulse in pulses) {
      final elapsed = now.difference(pulse.startTime).inMilliseconds;
      if (elapsed > pulseDurationMs) continue;

      final progress = elapsed / pulseDurationMs;
      final currentRadius = maxRadius * progress;
      final fadeOut = (1.0 - progress).clamp(0.0, 1.0);

      // 仅在高亮范围内绘制增强网格
      final pulsePaint = Paint()
        ..color = gridColor.withValues(alpha: pulseAlpha * fadeOut)
        ..strokeWidth = pulseStroke
        ..maskFilter = isGold ? const MaskFilter.blur(BlurStyle.normal, 6) : null;

      // 绘制受脉冲影响的横线
      for (double y = 0; y <= size.height; y += spacing) {
        final distToY = (y - pulse.center.dy).abs();
        if (distToY < currentRadius) {
          // 计算该行在圆内的范围
          final halfWidth = sqrt(pow(currentRadius, 2) - pow(distToY, 2));
          final startX = (pulse.center.dx - halfWidth).clamp(0.0, size.width);
          final endX = (pulse.center.dx + halfWidth).clamp(0.0, size.width);
          if (startX < endX) {
            canvas.drawLine(Offset(startX, y), Offset(endX, y), pulsePaint);
          }
        }
      }

      // 绘制受脉冲影响的竖线
      for (double x = 0; x <= size.width; x += spacing) {
        final distToX = (x - pulse.center.dx).abs();
        if (distToX < currentRadius) {
          final halfHeight = sqrt(pow(currentRadius, 2) - pow(distToX, 2));
          final startY = (pulse.center.dy - halfHeight).clamp(0.0, size.height);
          final endY = (pulse.center.dy + halfHeight).clamp(0.0, size.height);
          if (startY < endY) {
            canvas.drawLine(Offset(x, startY), Offset(x, endY), pulsePaint);
          }
        }
      }
      
      // 绘制一个淡淡的扩散圆环
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringStroke
        ..color = gridColor.withValues(alpha: ringAlpha * fadeOut)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ringBlur);
      
      canvas.drawCircle(pulse.center, currentRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => pulses.isNotEmpty || oldDelegate.pulses.isNotEmpty;
}
 
class _FireOverlayPainter extends CustomPainter {
  final DateTime start;
  _FireOverlayPainter(this.start);
  @override
  void paint(Canvas canvas, Size size) {
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    final dur = 1600.0;
    final p = (elapsed / dur).clamp(0.0, 1.0);
    final grad = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        const Color(0xFFFF8C00).withValues(alpha: 0.35 * (1.0 - p)),
        const Color(0xFFFF4500).withValues(alpha: 0.25 * (1.0 - p)),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = grad,
    );
    final rnd = Random(777);
    for (int i = 0; i < 24; i++) {
      final x = rnd.nextDouble() * size.width;
      final h = size.height * (0.2 + rnd.nextDouble() * 0.5);
      final w = 2.0 + rnd.nextDouble() * 3.0;
      final yTop = size.height * (1.0 - p);
      final rect = Rect.fromLTWH(x, yTop, w, h);
      final col = Color.lerp(const Color(0xFFFFD700), const Color(0xFFFF4500), rnd.nextDouble())!
          .withValues(alpha: 0.18 * (1.0 - p));
      canvas.drawRect(rect, Paint()..color = col);
    }
  }
  @override
  bool shouldRepaint(covariant _FireOverlayPainter oldDelegate) => true;
}
 
class _WaveIdlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = const Color(0xFF4DCCFF);
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    for (int i = 0; i < 2; i++) {
      final amp = 10.0 - i * 3.0;
      final freq = 0.010 + i * 0.004;
      final phase = t * (1.2 + i * 0.6);
      final path = Path()..moveTo(0, size.height * 0.15 + i * 12 + amp * sin(phase));
      for (double x = 0; x <= size.width; x += 6) {
        final y = size.height * 0.15 + i * 12 + amp * sin(x * freq + phase);
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = base.withValues(alpha: 0.12 - i * 0.03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 - i * 0.4,
      );
    }
  }
  @override
  bool shouldRepaint(covariant _WaveIdlePainter oldDelegate) => true;
}
