import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'card_data.dart';
import 'game_state.dart';
import 'level_data.dart';
import 'character_data.dart';
import 'animation_constants.dart';

/// 统一管理卡牌样式、配色和系列相关配置
class ThemeConfig {
  /// 默认卡牌基础颜色 (青色)
  static const Color defaultCardColor = Color(0xFF6CE4FF);

  /// 根据职业获取颜色
  static Color getClassColor(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.xueye: return const Color(0xFFFF4D4D);
      case CharacterClass.lin: return const Color(0xFFC3A6FF);
      case CharacterClass.langchao: return const Color(0xFF4DCCFF);
      case CharacterClass.jianren: return const Color(0xFFFFD700);
      case CharacterClass.yanxin: return const Color(0xFFFF8C00);
      case CharacterClass.yingshi: return const Color(0xFF4CAF50);
      case CharacterClass.jihe: return const Color(0xFF00BCD4);
      case CharacterClass.xuxing: return const Color(0xFF9E9E9E);
      case CharacterClass.fa: return const Color(0xFF673AB7);
    }
  }

  /// 根据职业获取图标
  static IconData getClassIcon(CharacterClass characterClass) {
    switch (characterClass) {
      case CharacterClass.xueye: return Icons.favorite;
      case CharacterClass.lin: return Icons.account_tree;
      case CharacterClass.langchao: return Icons.waves;
      case CharacterClass.jianren: return Icons.colorize;
      case CharacterClass.yanxin: return Icons.local_fire_department;
      case CharacterClass.yingshi: return Icons.visibility_off;
      case CharacterClass.jihe: return Icons.category;
      case CharacterClass.xuxing: return Icons.blur_on;
      case CharacterClass.fa: return Icons.gavel;
    }
  }

  /// 根据卡牌套装(Suite)确定视觉风格颜色
  static Color getSuiteColor(CardSuite suite) {
    switch (suite) {
      case CardSuite.classic:
        return defaultCardColor;
      case CardSuite.overload:
        return const Color(0xFFFF4444); // 红色
      case CardSuite.secure:
        return const Color(0xFFC3A6FF); // 紫色
      case CardSuite.industrial:
        return const Color(0xFFFFB344); // 橙色
      case CardSuite.quantum:
        return const Color(0xFFE26CFF); // 粉色
      case CardSuite.demon:
        return const Color(0xFF9D00FF); // 深紫色
      case CardSuite.holy:
        return const Color(0xFFFFD700); // 金色
    }
  }

  /// 根据稀有度等级获取颜色
  static Color getRarityColor(int level, {CardSuite? suite}) {
    if (suite == CardSuite.demon || suite == CardSuite.holy) {
      return const Color(0xFFFF0000); // 特殊牌红
    }
    switch (level) {
      case 1:
        return const Color(0xFF44FF44); // 绿色
      case 2:
        return defaultCardColor; // 主题蓝/青
      case 3:
        return const Color(0xFFE26CFF); // 粉紫色
      case 4:
        return const Color(0xFFFFD700); // 金色
      case 5:
        return const Color(0xFFFF4444); // 红色
      default:
        return Colors.white70;
    }
  }

  /// 获取卡牌背景色
  static Color getCardBgColor(CardSuite suite) {
    switch (suite) {
      case CardSuite.overload:
        return const Color(0xFF1A0A0A);
      case CardSuite.secure:
        return const Color(0xFF1A0A1A);
      case CardSuite.industrial:
        return const Color(0xFF1A140A);
      case CardSuite.quantum:
        return const Color(0xFF140A1A);
      case CardSuite.classic:
        return const Color(0xFF101722);
      case CardSuite.demon:
        return const Color(0xFF0F001A);
      case CardSuite.holy:
        return const Color(0xFF1A1A0A);
    }
  }

  /// 获取套装对应的图标
  static IconData getSuiteIcon(CardSuite suite) {
    switch (suite) {
      case CardSuite.classic:
        return Icons.bolt_rounded;
      case CardSuite.overload:
        return Icons.warning_amber_rounded;
      case CardSuite.secure:
        return Icons.security_rounded;
      case CardSuite.industrial:
        return Icons.settings_rounded;
      case CardSuite.quantum:
        return Icons.auto_awesome_rounded;
      case CardSuite.demon:
        return Icons.pest_control_rodent_rounded;
      case CardSuite.holy:
        return Icons.auto_awesome;
    }
  }

  /// 获取卡牌类型的显示文本
  static String getTypeName(CardType type) {
    switch (type) {
      case CardType.exploit:
        return 'EXPLOIT';
      case CardType.encryption:
        return 'ENCRYPT';
      case CardType.routine:
        return 'ROUTINE';
      case CardType.module:
        return 'MODULE';
    }
  }

  /// 统一构建卡牌描述文本，智能识别正面/负面效果并着色
  static Widget buildCardDescription(CardData c, Color highlightColor) {
    final String text = c.description ?? "";
    if (text.isEmpty) return const SizedBox.shrink();

    // 关键词分类
    const buffKeywords = {'防火墙加固', '算力', '系统修复', '能量', '能量点', '数据包', '带宽', '接入点', '两次'};
    const debuffKeywords = {'虚弱', '脆弱', '漏洞暴露', '恶意代码'};
    const damageKeywords = {'冲击', '自损', '受损', '过载伤害'};

    final regex = RegExp(r'(\d+)|(冲击|防火墙加固|数据包|算力|虚弱|脆弱|恶意代码|自损|系统修复|能量|能量点|漏洞暴露|受损|带宽|过载伤害|接入点|两次)');
    final List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 8.5,
          ),
        ));
      }

      final isNumber = match.group(1) != null;
      final matchText = match.group(0)!;

      // 智能判断颜色
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
      if (associatedKeyword == "自损" || associatedKeyword == "受损") {
        target = CardTarget.self;
      }

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
          fontSize: isNumber ? 10.5 : 9.5,
          fontFamily: 'monospace',
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
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 8.5,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: const TextStyle(
          fontFamily: 'monospace',
          height: 1.4,
        ),
      ),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 统一构建卡牌小部件
  static Widget buildCardWidget(CardData c, {double width = 84, double height = 112, bool dragging = false}) {
    final suiteColor = getSuiteColor(c.suite);
    final rarityColor = getRarityColor(c.level, suite: c.suite);
    final cardBgColor = getCardBgColor(c.suite).withValues(alpha: 0.9);
    
    return Container(
      width: width,
      height: height,
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
                        child: Builder(
                          builder: (_) {
                            final name = c.name;
                            final base = width * 0.11; // 动态计算基础字号
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
                              getSuiteIcon(c.suite),
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
                  Expanded(
                    child: buildCardDescription(c, suiteColor),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (c.suite == CardSuite.demon || c.suite == CardSuite.holy) ? "Lv ?" : "Lv${c.level}",
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
    );
  }

  static Widget _smallTargetIcon(CardTarget target, Color color) {
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
    return Icon(icon, size: 8, color: color.withValues(alpha: 0.6));
  }
}

/// 辅助 Painter
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
        final random = math.Random(42);
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
      case CardSuite.demon:
        // 恶魔：放射状的尖锐线条
        final center = Offset(size.width * 0.5, size.height * 0.5);
        for (int i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          canvas.drawLine(
            center,
            center + Offset(math.cos(angle) * 30, math.sin(angle) * 30),
            paint..strokeWidth = 2.0,
          );
        }
        break;
      case CardSuite.holy:
        // 神圣：大型十字架背景
        final centerX = size.width * 0.5;
        final centerY = size.height * 0.5;
        final crossWidth = size.width * 0.5;
        final crossHeight = size.height * 0.7;
        final barThickness = 4.0;
        
        // 垂直条
        canvas.drawRect(
          Rect.fromLTWH(centerX - barThickness / 2, centerY - crossHeight * 0.5, barThickness, crossHeight),
          paint..style = PaintingStyle.fill,
        );
        // 水平条 (位置稍高，形成拉丁十字)
        canvas.drawRect(
          Rect.fromLTWH(centerX - crossWidth * 0.5, centerY - crossHeight * 0.2, crossWidth, barThickness),
          paint..style = PaintingStyle.fill,
        );
        
        // 周围的发光圆环
        canvas.drawCircle(
          Offset(centerX, centerY - crossHeight * 0.2), 
          12, 
          paint..style = PaintingStyle.stroke..strokeWidth = 0.5
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 扫描线与抖动效果画笔
class CyberScanlineJitterPainter extends CustomPainter {
  final double strength;
  final Color? color;

  const CyberScanlineJitterPainter({required this.strength, this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (color ?? GameState.getThemeColor()).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 3) {
      final jitter = math.sin(y / 12) * strength;
      canvas.drawLine(Offset(jitter, y), Offset(size.width + jitter, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CyberScanlineJitterPainter oldDelegate) =>
      oldDelegate.strength != strength || oldDelegate.color != color;
}

/// 全息塔装饰画笔
class CyberHoloTowerPainter extends CustomPainter {
  final double progress;
  final Color? color;

  CyberHoloTowerPainter({required this.progress, this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height * 0.8;
    final towerHeight = size.height * 0.55;
    final towerWidthBase = size.width * 0.12;
    final towerTopY = baseY - towerHeight;

    final themeColor = color ?? GameState.getThemeColor();
    const ringCount = 6;
    for (int i = 0; i < ringCount; i++) {
      final p = ((progress + i / ringCount) % 1.0);
      final alpha = (1.0 - p) * 0.25;
      final radius = towerWidthBase * 1.2 + p * size.width * 0.25;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = themeColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(centerX, towerTopY + towerHeight * 0.2), radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CyberHoloTowerPainter oldDelegate) => true;
}

/// 斩击特效画笔
class CyberSlashPainter extends CustomPainter {
  final Offset center;
  final double progress;
  final Color color;

  CyberSlashPainter({
    required this.center,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final t = progress.clamp(0.0, 1.0);
    final alpha = (1.0 - t);
    final baseWidth = 6.0 * alpha;
    const radius = 120.0;
    final angle = (-math.pi / 6) + (math.pi / 3) * Curves.easeOut.transform(t);

    // 构造弧形路径（二次贝塞尔）
    Path buildArc(Offset c, double r, double a, double bend) {
      final dir = Offset(math.cos(a), math.sin(a));
      final normal = Offset(-dir.dy, dir.dx);
      final start = c - dir * r * 0.6 - normal * r * 0.15;
      final end = c + dir * r * 0.6 + normal * r * 0.05;
      final ctrl = c + normal * r * bend;
      final p = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      return p;
    }

    // 光晕层
    final glow = Paint()
      ..color = color.withValues(alpha: alpha * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth * 2.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // 主体层
    final stroke = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth
      ..strokeCap = StrokeCap.round;

    // 核心白光
    final core = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth * 0.45
      ..strokeCap = StrokeCap.round;

    // 主斩击
    final bend = 0.25 + 0.15 * (1.0 - alpha);
    final arc = buildArc(center, radius, angle, bend);
    canvas.drawPath(arc, glow);
    canvas.drawPath(arc, stroke);
    canvas.drawPath(arc, core);

    // 尾迹层（多重残影）
    for (int i = 1; i <= 3; i++) {
      final trailAlpha = (alpha * (0.6 - i * 0.15)).clamp(0.0, 1.0);
      if (trailAlpha <= 0) continue;
      final trail = Paint()
        ..color = color.withValues(alpha: trailAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseWidth * (1.0 - i * 0.15)
        ..strokeCap = StrokeCap.round;
      final offset = Offset(-math.sin(angle), math.cos(angle)) * (i * 6.0);
      final arcTrail = buildArc(center + offset, radius * (1.0 - i * 0.06), angle, bend * (1.0 - i * 0.1));
      canvas.drawPath(arcTrail, trail);
    }
  }

  @override
  bool shouldRepaint(covariant CyberSlashPainter oldDelegate) => true;
}

/// 激光特效画笔
class CyberLaserPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;
  final Color color;
  final double width;
  final double opacity;

  CyberLaserPainter({
    required this.start,
    required this.end,
    required this.progress,
    required this.color,
    required this.width,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.3)
      ..strokeWidth = width * 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, glowPaint);
    canvas.drawLine(start, end, paint);

    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = width * 0.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, corePaint);
  }

  @override
  bool shouldRepaint(covariant CyberLaserPainter oldDelegate) => true;
}

/// 战斗网格脉冲模型
class GridPulse {
  final Offset center;
  final DateTime startTime;
  GridPulse(this.center) : startTime = DateTime.now();
}

/// 角色特效模型
class RoleEffect {
  final CharacterClass role;
  final Offset pos;
  final DateTime startTime;
  RoleEffect(this.role, this.pos) : startTime = DateTime.now();
}

/// 战斗区域动态网格画笔
class CyberBattleGridPainter extends CustomPainter {
  final List<GridPulse> pulses;
  final Color gridColor;
  CyberBattleGridPainter({required this.pulses, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    const spacing = 40.0;
    const maxRadius = 1000.0;
    final pulseDurationMs = AnimDurations.gridPulse.inMilliseconds;
    final isGold = gridColor == const Color(0xFFFFD700);
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
          final halfWidth = math.sqrt(math.pow(currentRadius, 2) - math.pow(distToY, 2));
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
          final halfHeight = math.sqrt(math.pow(currentRadius, 2) - math.pow(distToX, 2));
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
  bool shouldRepaint(covariant CyberBattleGridPainter oldDelegate) => pulses.isNotEmpty || oldDelegate.pulses.isNotEmpty;
}

/// 角色专属特效绘制画笔
class CyberRoleEffectPainter extends CustomPainter {
  final List<RoleEffect> effects;
  CyberRoleEffectPainter(this.effects);

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
          break;
      }
    }
  }

  void _drawLinShieldEffect(Canvas canvas, Size size, Offset center, double progress) {
    final pink = const Color(0xFFC3A6FF);
    final purple = const Color(0xFF7A3BFF);
    final a = (1.0 - progress).clamp(0.0, 1.0);
    final edgeColor = Color.lerp(purple, pink, 0.5)!.withValues(alpha: 0.5 * a);
    final topRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.14);
    final bottomRect = Rect.fromLTWH(0, size.height * 0.86, size.width, size.height * 0.14);
    final leftRect = Rect.fromLTWH(0, 0, size.width * 0.10, size.height);
    final rightRect = Rect.fromLTWH(size.width * 0.90, 0, size.width * 0.10, size.height);
    final topShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFC3A6FF), Color(0x00C3A6FF)],
    ).createShader(topRect);
    final bottomShader = const LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFFC3A6FF), Color(0x00C3A6FF)],
    ).createShader(bottomRect);
    final leftShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFC3A6FF), Color(0x00C3A6FF)],
    ).createShader(leftRect);
    final rightShader = const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFFC3A6FF), Color(0x00C3A6FF)],
    ).createShader(rightRect);
    canvas.drawRect(topRect, Paint()..shader = topShader..colorFilter = ColorFilter.mode(edgeColor, BlendMode.srcIn));
    canvas.drawRect(bottomRect, Paint()..shader = bottomShader..colorFilter = ColorFilter.mode(edgeColor, BlendMode.srcIn));
    canvas.drawRect(leftRect, Paint()..shader = leftShader..colorFilter = ColorFilter.mode(edgeColor, BlendMode.srcIn));
    canvas.drawRect(rightRect, Paint()..shader = rightShader..colorFilter = ColorFilter.mode(edgeColor, BlendMode.srcIn));
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
      final path = Path()..moveTo(0, crestY + amp * math.sin(phase));
      for (double x = 0; x <= size.width; x += 6) {
        final y = crestY + amp * math.sin(x * freq + phase);
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

  void _drawFireParticles(Canvas canvas, Size size, Offset center, double progress) {
    final random = math.Random(123);
    for (int i = 0; i < 20; i++) {
      final paint = Paint()
        ..color = Color.lerp(const Color(0xFFFFD700), const Color(0xFFFF4500), random.nextDouble())!
            .withValues(alpha: (1.0 - progress) * 0.8);
      
      final x = center.dx + (random.nextDouble() - 0.5) * size.width * 0.6;
      final y = center.dy + (random.nextDouble() - 0.5) * 50 - (progress * 200);
      
      canvas.drawCircle(Offset(x, y), 2 + random.nextDouble() * 4, paint);
    }
  }

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

  void _drawHexGrid(Canvas canvas, Size size, Offset center, double progress) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: (1.0 - progress) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final hexSize = 40.0;
    final rowHeight = hexSize * 1.5;
    final colWidth = hexSize * math.sqrt(3);
    final radius = (progress * size.width).clamp(0.0, size.width);
    final band = 60.0;
    final minY = (center.dy - radius - band).clamp(0.0, size.height);
    final maxY = (center.dy + radius + band).clamp(0.0, size.height);
    final startRow = (minY / rowHeight).floor();
    final endRow = (maxY / rowHeight).ceil();
    final rows = endRow.clamp(0, (size.height / rowHeight).ceil());
    final startCol = ((center.dx - radius - band) / colWidth).floor().clamp(0, (size.width / colWidth).ceil());
    final endCol = ((center.dx + radius + band) / colWidth).ceil().clamp(0, (size.width / colWidth).ceil());

    for (int r = startRow; r < rows; r++) {
      for (int c = startCol; c < endCol; c++) {
        final x = c * colWidth + (r % 2 == 0 ? 0 : colWidth / 2);
        final y = r * rowHeight;
        
        final dist = (Offset(x, y) - center).distance;
        if ((dist - radius).abs() < band) {
          _drawHex(canvas, Offset(x, y), hexSize, paint);
        }
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawGlitchSquares(Canvas canvas, Size size, Offset center, double progress) {
    final random = math.Random(777);
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

  @override
  bool shouldRepaint(CyberRoleEffectPainter oldDelegate) => true;
}

/// 血条背景斜纹画笔
class CyberHpBarBackgroundPainter extends CustomPainter {
  final Color color;
  CyberHpBarBackgroundPainter({required this.color});

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

/// 顶部状态栏斜纹画笔
class CyberTopBarGridPainter extends CustomPainter {
  final Color color;
  final double progress;
  CyberTopBarGridPainter({required this.color, required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final base = color.withValues(alpha: 0.04 + 0.08 * Curves.easeOut.transform(progress.clamp(0.0, 1.0)));
    final p = Paint()
      ..color = base
      ..strokeWidth = 1.0;
    final spacing = 24.0 - 8.0 * Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    for (double x = -size.height; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
    for (double x = size.width + size.height; x > 0; x -= spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), p);
    }
  }
  @override
  bool shouldRepaint(covariant CyberTopBarGridPainter oldDelegate) => oldDelegate.color != color || oldDelegate.progress != progress;
}

/// 全屏发光边缘画笔 (警告/低血量效果)
class CyberScreenGlowPainter extends CustomPainter {
  final double alpha;
  final Color color;
  CyberScreenGlowPainter({required this.alpha, this.color = const Color(0xFFFF4D4D)});
  @override
  void paint(Canvas canvas, Size size) {
    final glowColor = color.withValues(alpha: alpha);
    
    // 顶部发光
    Rect top = Rect.fromLTWH(0, 0, size.width, size.height * 0.08);
    Paint pt = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(top);
    canvas.drawRect(top, pt..colorFilter = ColorFilter.mode(glowColor, BlendMode.srcIn));
    
    // 底部发光
    Rect bottom = Rect.fromLTWH(0, size.height * 0.92, size.width, size.height * 0.08);
    Paint pb = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(bottom);
    canvas.drawRect(bottom, pb..colorFilter = ColorFilter.mode(glowColor, BlendMode.srcIn));
    
    // 左侧发光
    Rect left = Rect.fromLTWH(0, 0, size.width * 0.06, size.height);
    Paint pl = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(left);
    canvas.drawRect(left, pl..colorFilter = ColorFilter.mode(glowColor, BlendMode.srcIn));
    
    // 右侧发光
    Rect right = Rect.fromLTWH(size.width * 0.94, 0, size.width * 0.06, size.height);
    Paint pr = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(right);
    canvas.drawRect(right, pr..colorFilter = ColorFilter.mode(glowColor, BlendMode.srcIn));
  }
  @override
  bool shouldRepaint(covariant CyberScreenGlowPainter oldDelegate) => oldDelegate.alpha != alpha || oldDelegate.color != color;
}

/// 火焰覆盖层画笔
class CyberFireOverlayPainter extends CustomPainter {
  final DateTime start;
  CyberFireOverlayPainter(this.start);
  Size? _lastSize;
  List<Rect>? _stripes;
  List<Color>? _stripeColors;
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
    if (_lastSize != size || _stripes == null || _stripeColors == null) {
      _lastSize = size;
      final rnd = math.Random(777);
      _stripes = List.generate(24, (_) {
        final x = rnd.nextDouble() * size.width;
        final h = size.height * (0.2 + rnd.nextDouble() * 0.5);
        final w = 2.0 + rnd.nextDouble() * 3.0;
        return Rect.fromLTWH(x, 0, w, h);
      });
      _stripeColors = List.generate(24, (_) =>
        Color.lerp(const Color(0xFFFFD700), const Color(0xFFFF4500), rnd.nextDouble())!.withValues(alpha: 0.18)
      );
    }
    final yTop = size.height * (1.0 - p);
    for (int i = 0; i < (_stripes!.length); i++) {
      final base = _stripes![i];
      final rect = Rect.fromLTWH(base.left, yTop, base.width, base.height);
      final col = _stripeColors![i].withValues(alpha: 0.18 * (1.0 - p));
      canvas.drawRect(rect, Paint()..color = col);
    }
  }
  @override
  bool shouldRepaint(covariant CyberFireOverlayPainter oldDelegate) => true;
}

/// 海浪待机背景画笔
class CyberWaveIdlePainter extends CustomPainter {
  CyberWaveIdlePainter({super.repaint});
  @override
  void paint(Canvas canvas, Size size) {
    final base = const Color(0xFF4DCCFF);
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    for (int i = 0; i < 2; i++) {
      final amp = 10.0 - i * 3.0;
      final freq = 0.010 + i * 0.004;
      final phase = t * (1.2 + i * 0.6);
      final path = Path()..moveTo(0, size.height * 0.15 + i * 12 + amp * math.sin(phase));
      for (double x = 0; x <= size.width; x += 8) {
        final y = size.height * 0.15 + i * 12 + amp * math.sin(x * freq + phase);
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = base.withValues(alpha: 0.08 - i * 0.03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }
  }
  @override
  bool shouldRepaint(covariant CyberWaveIdlePainter oldDelegate) => true;
}

class CyberCampfireCorePainter extends CustomPainter {
  final Color color;
  final double pulse;
  CyberCampfireCorePainter({required this.color, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.8, ringPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pulse * 2 * math.pi);
    final tickPaint = Paint()..color = color..strokeWidth = 3;
    for (int i = 0; i < 6; i++) {
      canvas.rotate(math.pi / 3);
      canvas.drawLine(Offset(radius * 0.82, 0), Offset(radius * 0.92, 0), tickPaint);
    }
    canvas.restore();

    final gradient = RadialGradient(
      colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.0)],
    ).createShader(Rect.fromCircle(center: center, radius: radius * 0.18));
    final corePaint = Paint()..shader = gradient;
    canvas.drawCircle(center, radius * 0.12 * (1 + pulse * 0.25), corePaint);

    final flamePaint = Paint()..color = color.withValues(alpha: 0.6);
    final path = Path()
      ..moveTo(center.dx, center.dy - radius * 0.18)
      ..cubicTo(center.dx + radius * 0.08, center.dy - radius * 0.1, center.dx + radius * 0.05, center.dy, center.dx, center.dy + radius * 0.1)
      ..cubicTo(center.dx - radius * 0.05, center.dy, center.dx - radius * 0.08, center.dy - radius * 0.1, center.dx, center.dy - radius * 0.18);
    canvas.drawPath(path, flamePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CyberNationMapPainter extends CustomPainter {
  final List<Nation> nations;
  final String? hoveredId;
  final Animation<double> pulse;
  final Map<String, Offset>? positions;
  final List<List<String>> edges;
  final Color themeColor;

  CyberNationMapPainter({
    required this.nations,
    required this.hoveredId,
    required this.pulse,
    required this.positions,
    required this.edges,
    required this.themeColor,
  }) : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {
    if (positions != null && positions!.isNotEmpty) {
      for (final e in edges) {
        final a = positions![e[0]]!;
        final b = positions![e[1]]!;
        final grad = Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [themeColor.withValues(alpha: 0.13), const Color(0x22FFD700)],
          ).createShader(Rect.fromPoints(a, b))
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(a, b, grad);
      }
    }
  }

  @override
  bool shouldRepaint(CyberNationMapPainter oldDelegate) =>
      oldDelegate.hoveredId != hoveredId ||
      oldDelegate.positions != positions ||
      oldDelegate.edges.length != edges.length;
}

/// 拓扑背景装饰
class CyberTopologyBackgroundPainter extends CustomPainter {
  final Color themeColor;
  CyberTopologyBackgroundPainter({required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = themeColor.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    // 绘制主网格 (对角线)
    const spacing = 60.0;
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i - size.height, size.height), paint);
    }

    // 绘制随机数据点
    final random = math.Random(42); // 固定种子保证背景稳定
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5;
      final dotPaint = Paint()
        ..color = themeColor.withValues(alpha: random.nextDouble() * 0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
      
      // 偶尔绘制十字线
      if (random.nextDouble() > 0.8) {
        final crossSize = 4.0;
        canvas.drawLine(Offset(x - crossSize, y), Offset(x + crossSize, y), dotPaint);
        canvas.drawLine(Offset(x, y - crossSize), Offset(x, y + crossSize), dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 漂浮的数据装饰效果
class CyberFloatingDataPainter extends CustomPainter {
  final double progress;
  final Color? color;
  CyberFloatingDataPainter({required this.progress, this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final themeColor = color ?? GameState.getThemeColor();

    final randomPositions = [
      const Offset(0.1, 0.2),
      const Offset(0.8, 0.15),
      const Offset(0.2, 0.7),
      const Offset(0.75, 0.85),
      const Offset(0.15, 0.4),
      const Offset(0.85, 0.6),
    ];

    final dataStrings = [
      "010110",
      "X-772",
      "RECV: OK",
      "SYS_INIT",
      "TCP_SYN",
      "PORT:80",
    ];

    for (int i = 0; i < randomPositions.length; i++) {
      final pos = randomPositions[i];
      // 缓慢上下漂浮
      final floatOffset = Offset(
        pos.dx * size.width,
        pos.dy * size.height + (i % 2 == 0 ? 10 : -10) * progress,
      );

      textPainter.text = TextSpan(
        text: dataStrings[i % dataStrings.length],
        style: TextStyle(
          color: themeColor.withValues(alpha: 0.15),
          fontSize: 8,
          fontFamily: 'monospace',
          letterSpacing: 2,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, floatOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CyberFloatingDataPainter oldDelegate) => true;
}

/// 科幻风格路径绘制
class CyberMapPathPainter extends CustomPainter {
  final List<List<dynamic>> layers;
  final double pulseProgress;
  final Color themeColor;
  final int currentLayer;
  final String? currentLevelId;

  CyberMapPathPainter({
    required this.layers,
    required this.pulseProgress,
    required this.themeColor,
    required this.currentLayer,
    this.currentLevelId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final layerHeight = size.height / (layers.length + 1);

    for (int i = 0; i < layers.length - 1; i++) {
      final currentLayerNodes = layers[i];
      final nextLayerNodes = layers[i + 1];

      for (int j = 0; j < currentLayerNodes.length; j++) {
        final currentNode = currentLayerNodes[j];
        
        // 假设 currentNode 具有 nextLevelIndices 属性
        final List<int> nextIndices = (currentNode as dynamic).nextLevelIndices;
        
        for (final nextIdx in nextIndices) {
          if (nextIdx >= nextLayerNodes.length) continue;
          
          final nextNode = nextLayerNodes[nextIdx];
          
          // 判定逻辑 - 需要外部传入或通过 GameProgress 访问
          // 这里我们采用更通用的逻辑判断
          final bool isCurrentNodeActive = i == currentLayer && (currentNode as dynamic).id == currentLevelId;
          
          // 获取节点的击败状态 (这里假设有 isDefeated 函数或类似逻辑)
          // 为了保持通用性，我们通过回调或预计算传入状态。
          // 但在本项目中，我们直接引用 GameProgress。
          // 注意：theme_config.dart 应该尽量减少对具体业务逻辑的依赖，
          // 但为了方便迁移，我们暂时保持这种引用。
          
          final bool isPathDefeated = GameProgress.isDefeated((currentNode as dynamic).id) && 
                                     GameProgress.isDefeated((nextNode as dynamic).id);
          final bool isNextAccessible = isCurrentNodeActive;

          // 路径颜色
          Color pathColor;
          double opacity = 0.3;
          double strokeWidth = 1.0;
          bool isPulsePath = isPathDefeated || isNextAccessible;

          if (isPathDefeated) {
            pathColor = themeColor;
            opacity = 0.5;
            strokeWidth = 1.5;
          } else if (isNextAccessible) {
            pathColor = themeColor;
            opacity = 0.8;
            strokeWidth = 2.0;
          } else {
            pathColor = const Color(0xFF2A4158);
            opacity = 0.2;
            strokeWidth = 1.0;
          }

          // 计算精确位置
          final currentY = size.height - layerHeight * (i + 1);
          final nextY = size.height - layerHeight * (i + 2);
          final currentX = size.width * (j + 1) / (currentLayerNodes.length + 1);
          final nextX = size.width * (nextIdx + 1) / (nextLayerNodes.length + 1);

          final pathPaint = Paint()
            ..color = pathColor.withValues(alpha: opacity)
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

          // 为活跃路径添加发光效果
          if (isPulsePath) {
            final glowPaint = Paint()
              ..color = pathColor.withValues(alpha: opacity * 0.3)
              ..strokeWidth = strokeWidth * 3
              ..style = PaintingStyle.stroke
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
            
            final glowPath = Path()..moveTo(currentX, currentY);
            final controlY = (currentY + nextY) / 2;
            glowPath.cubicTo(currentX, controlY, nextX, controlY, nextX, nextY);
            canvas.drawPath(glowPath, glowPaint);
          }

          final path = Path()..moveTo(currentX, currentY);
          final controlY = (currentY + nextY) / 2;
          path.cubicTo(currentX, controlY, nextX, controlY, nextX, nextY);

          canvas.drawPath(path, pathPaint);

          // 数据流脉冲
          if (isPulsePath) {
            final pathMetrics = path.computeMetrics();
            for (final metric in pathMetrics) {
              for (int k = 0; k < 3; k++) {
                double offsetPercent = (pulseProgress + k * 0.33) % 1.0;
                final tangent = metric.getTangentForOffset(metric.length * offsetPercent);
                if (tangent == null) continue;
                
                final pos = tangent.position;
                
                final pulsePaint = Paint()
                  ..color = pathColor.withValues(alpha: 0.9)
                  ..style = PaintingStyle.fill;
                
                final pulseGlowPaint = Paint()
                  ..color = pathColor.withValues(alpha: 0.4)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

                canvas.drawCircle(pos, 2.0, pulseGlowPaint);
                canvas.drawCircle(pos, 1.2, pulsePaint);
                
                final prevTangent = metric.getTangentForOffset(metric.length * (offsetPercent - 0.05).clamp(0, 1));
                if (prevTangent != null) {
                  final tailPaint = Paint()
                    ..color = pathColor.withValues(alpha: 0.4)
                    ..strokeWidth = 1.5
                    ..strokeCap = StrokeCap.round;
                  canvas.drawLine(pos, prevTangent.position, tailPaint);
                }
              }
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(CyberMapPathPainter oldDelegate) =>
      oldDelegate.pulseProgress != pulseProgress ||
      oldDelegate.themeColor != themeColor ||
      oldDelegate.currentLevelId != currentLevelId ||
      oldDelegate.currentLayer != currentLayer;
}

enum CyberHoloDirection { vertical, horizontal }

/// 全局通用的全息网格扫描效果绘制
class CyberHoloGridPainter extends CustomPainter {
  final double progress;
  final CyberHoloDirection direction;

  CyberHoloGridPainter({
    required this.progress,
    this.direction = CyberHoloDirection.vertical,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.05) {
      return;
    }
    final p = progress.clamp(0.0, 1.0);

    double regionStart;
    double regionEnd;
    final totalSize = direction == CyberHoloDirection.vertical ? size.height : size.width;

    if (p < 0.7) {
      final appear = p / 0.7;
      regionStart = 0;
      regionEnd = totalSize * appear;
    } else {
      final disappear = (p - 0.7) / 0.3;
      regionStart = totalSize * disappear;
      regionEnd = totalSize;
    }

    if (regionEnd <= regionStart) {
      return;
    }

    final themeColor = GameState.getThemeColor();
    final gridColor = themeColor.withValues(alpha: 0.2);
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1;

    const cell = 16.0;
    if (direction == CyberHoloDirection.vertical) {
      for (double y = regionStart; y <= regionEnd; y += cell) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
      for (double x = 0; x <= size.width; x += cell) {
        canvas.drawLine(Offset(x, regionStart), Offset(x, regionEnd), gridPaint);
      }
    } else {
      for (double x = regionStart; x <= regionEnd; x += cell) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y <= size.height; y += cell) {
        canvas.drawLine(Offset(regionStart, y), Offset(regionEnd, y), gridPaint);
      }
    }

    const bandSize = 24.0;
    final bandStart = (regionEnd - bandSize).clamp(regionStart, regionEnd);
    final bandEnd = regionEnd;
    if (bandEnd <= bandStart) {
      return;
    }

    final bandRect = direction == CyberHoloDirection.vertical
        ? Rect.fromLTRB(0, bandStart, size.width, bandEnd)
        : Rect.fromLTRB(bandStart, 0, bandEnd, size.height);

    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: direction == CyberHoloDirection.vertical ? Alignment.topCenter : Alignment.centerLeft,
        end: direction == CyberHoloDirection.vertical ? Alignment.bottomCenter : Alignment.centerRight,
        colors: [themeColor.withValues(alpha: 0.0), themeColor.withValues(alpha: 0.26)],
      ).createShader(bandRect);
    canvas.drawRect(bandRect, bandPaint);
  }

  @override
  bool shouldRepaint(covariant CyberHoloGridPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.direction != direction;
  }
}

/// 赛博风格逻辑面板容器
class CyberLogicPanel extends StatelessWidget {
  final Color color;
  final Widget child;
  final IconData icon;
  final String label;
  final String sessionLabel;
  final double? maxWidth;

  const CyberLogicPanel({
    super.key,
    required this.color,
    required this.child,
    this.icon = Icons.qr_code_scanner,
    this.label = "// CHANNEL",
    this.sessionLabel = "SESSION",
    this.maxWidth = 720,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
        width: maxWidth != null ? null : double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.black,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            children: [
              Positioned.fill(
                child: CyberScanline(color: color.withValues(alpha: 0.08)),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: CyberCornerPainter(color: color.withValues(alpha: 0.5)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        sessionLabel,
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
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.8),
                          color.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
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
}

/// 赛博朋克风格背景
class CyberBackground extends StatelessWidget {
  const CyberBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = GameState.getThemeColor();
    return Stack(
      children: [
        // 基础渐变
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF05060A), Color(0xFF0C1018)],
            ),
          ),
        ),
        // 装饰性网格
        Positioned.fill(
          child: CustomPaint(
            painter: CyberGridPainter(
              color: themeColor,
              opacity: 0.03,
              showChars: false,
            ),
          ),
        ),
        // 扫描线
        Positioned.fill(
          child: CyberScanline(color: themeColor),
        ),
      ],
    );
  }
}

/// 科幻网格背景绘制
class CyberGridPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double spacing;
  final bool showChars;
  final double strokeWidth;

  CyberGridPainter({
    required this.color,
    this.opacity = 0.2,
    this.spacing = 40.0,
    this.showChars = true,
    this.strokeWidth = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = strokeWidth;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    
    if (showChars) {
      // 绘制一些随机的数字/字符装饰
      final textStyle = TextStyle(color: color.withValues(alpha: opacity * 2), fontSize: 6, fontFamily: 'monospace');
      for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 5; j++) {
          final tp = TextPainter(
            text: TextSpan(text: (i + j).toRadixString(16), style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(i * spacing * 2 + 5, j * spacing * 2 + 5));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 职业专属背景效果绘制
class CyberClassEffectPainter extends CustomPainter {
  final CharacterClass characterClass;
  final Color color;
  final double progress;

  CyberClassEffectPainter({
    required this.characterClass,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // 固定种子保证效果一致

    switch (characterClass) {
      case CharacterClass.xueye:
        // 红色脉冲效果
        final paint = Paint()
          ..color = color.withValues(alpha: 0.05)
          ..style = PaintingStyle.fill;
        
        for (int i = 0; i < 3; i++) {
          final p = (progress + i / 3) % 1.0;
          final radius = size.shortestSide * p;
          canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint..color = color.withValues(alpha: (1 - p) * 0.1));
        }
        break;

      case CharacterClass.lin:
        // 绿色数据流
        final paint = Paint()
          ..color = color.withValues(alpha: 0.1)
          ..strokeWidth = 1;
        
        for (int i = 0; i < 20; i++) {
          final x = random.nextDouble() * size.width;
          final speed = 0.5 + random.nextDouble();
          final y = (size.height * (progress * speed + random.nextDouble())) % size.height;
          canvas.drawLine(Offset(x, y), Offset(x, y + 20), paint);
        }
        break;

      case CharacterClass.langchao:
        // 蓝色波动
        final paint = Paint()
          ..color = color.withValues(alpha: 0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        
        final path = Path();
        for (int i = 0; i < 3; i++) {
          path.reset();
          final offset = i * 50.0;
          for (double x = 0; x < size.width; x += 5) {
            final y = size.height * 0.8 + math.sin((x / size.width * 2 * math.pi) + (progress * 2 * math.pi) + i) * 20;
            if (x == 0) {
              path.moveTo(x, y + offset);
            } else {
              path.lineTo(x, y + offset);
            }
          }
          canvas.drawPath(path, paint..color = color.withValues(alpha: 0.1 / (i + 1)));
        }
        break;

      default:
        // 默认淡淡的颜色晕染
        final rect = Rect.fromLTWH(0, 0, size.width, size.height);
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.05), Colors.transparent],
          ).createShader(rect);
        canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CyberClassEffectPainter oldDelegate) => true;
}

/// 赛博风格的战术分割线
class CyberTacticalDivider extends StatelessWidget {
  final Color color;
  final String? label;
  const CyberTacticalDivider({super.key, required this.color, this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Container(
              width: 8,
              height: 2,
              color: color,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.1)],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 赛博风格的信息行
class CyberInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const CyberInfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
          ],
          Text(
            "$label:",
            style: TextStyle(
              color: color.withValues(alpha: 0.5),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 职业专属背景效果组件
class CyberClassSpecialEffect extends StatefulWidget {
  final CharacterClass characterClass;
  const CyberClassSpecialEffect({super.key, required this.characterClass});

  @override
  State<CyberClassSpecialEffect> createState() => _CyberClassSpecialEffectState();
}

class _CyberClassSpecialEffectState extends State<CyberClassSpecialEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = ThemeConfig.getClassColor(widget.characterClass);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: CyberClassEffectPainter(
            characterClass: widget.characterClass,
            color: color,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

/// 雷达图绘制
class CyberRadarPainter extends CustomPainter {
  final Color color;
  final List<double> data;
  final List<String> labels;
  final double progress;

  CyberRadarPainter({
    required this.color,
    required this.data,
    required this.labels,
    this.progress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;
    final axisCount = data.length;
    final axisPaint = Paint()..color = color.withValues(alpha: 0.25 * progress)..strokeWidth = 1;
    final ringPaint = Paint()..color = color.withValues(alpha: 0.06 * progress);
    final ringStroke = Paint()..color = color.withValues(alpha: 0.2 * progress)..style = PaintingStyle.stroke..strokeWidth = 1;
    for (int r = 1; r <= 3; r++) {
      final rr = radius * (r / 3);
      canvas.drawCircle(center, rr, ringPaint);
      canvas.drawCircle(center, rr, ringStroke);
    }
    for (int i = 0; i < axisCount; i++) {
      final a = -math.pi / 2 + i * (2 * math.pi / axisCount);
      final end = Offset(center.dx + radius * math.cos(a), center.dy + radius * math.sin(a));
      canvas.drawLine(center, end, axisPaint);
    }
    final path = Path();
    for (int i = 0; i < axisCount; i++) {
      final a = -math.pi / 2 + i * (2 * math.pi / axisCount);
      final rr = radius * data[i].clamp(0.0, 1.0);
      final p = Offset(center.dx + rr * math.cos(a), center.dy + rr * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    final fill = Paint()..color = color.withValues(alpha: 0.25 * progress);
    final stroke = Paint()..color = color.withValues(alpha: 0.6 * progress)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    final tp = Paint()..color = color.withValues(alpha: 0.9 * progress);
    for (int i = 0; i < axisCount; i++) {
      final a = -math.pi / 2 + i * (2 * math.pi / axisCount);
      final end = Offset(center.dx + (radius + 18) * math.cos(a), center.dy + (radius + 18) * math.sin(a));
      final textPainter = TextPainter(text: TextSpan(text: labels[i], style: TextStyle(color: tp.color, fontSize: 10, fontFamily: 'monospace')), textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, end.translate(-textPainter.width / 2, -textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CyberRadarPainter oldDelegate) => 
    oldDelegate.data != data || oldDelegate.color != color || oldDelegate.progress != progress;
}

/// 雷达图组件
class CyberRadarChart extends StatefulWidget {
  final Color color;
  final List<double> data;
  final List<String> labels;

  const CyberRadarChart({
    super.key,
    required this.color,
    required this.data,
    required this.labels,
  });

  @override
  State<CyberRadarChart> createState() => _CyberRadarChartState();
}

class _CyberRadarChartState extends State<CyberRadarChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _progress,
          builder: (_, __) {
            final animatedData = widget.data.map((v) => v * _progress.value).toList();
            return CustomPaint(
              painter: CyberRadarPainter(
                color: widget.color,
                data: animatedData,
                labels: widget.labels,
                progress: _progress.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 赛博朋克风格全局提示
class CyberToast {
  static OverlayEntry? _currentEntry;
  static DateTime? _lastShowTime;
  static String? _lastMessage;

  static void show(BuildContext context, String message) {
    // 防抖与重复消息过滤
    final now = DateTime.now();
    if (_lastMessage == message && 
        _lastShowTime != null && 
        now.difference(_lastShowTime!) < const Duration(seconds: 2)) {
      return;
    }

    _lastMessage = message;
    _lastShowTime = now;

    _currentEntry?.remove();
    _currentEntry = OverlayEntry(
      builder: (context) => _CyberToastWidget(
        message: message,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }
}

class _CyberToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _CyberToastWidget({required this.message, required this.onDismiss});

  @override
  State<_CyberToastWidget> createState() => _CyberToastWidgetState();
}

class _CyberToastWidgetState extends State<_CyberToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // 2秒后自动消失
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = GameState.getThemeColor();
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.15,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacity.value,
                child: Transform.translate(
                  offset: _slide.value * 50,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
                      border: Border.all(
                        color: themeColor.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // 装饰边角
                        Positioned.fill(
                          child: CustomPaint(
                            painter: CyberCornerPainter(
                              color: themeColor.withValues(alpha: 0.5),
                              cornerSize: 8,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: themeColor,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'monospace',
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 赛博朋克风格按钮
class CyberButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final Color? color;
  final double fontSize;
  final String? heroTag;

  const CyberButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width = 240,
    this.height = 50,
    this.fontSize = 14,
    this.color,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;
    final Color effectiveColor = color ?? GameState.getThemeColor();
    final Color activeColor = isDisabled ? Colors.grey : effectiveColor;

    Widget button = Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: width,
          height: height,
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
              topLeft: Radius.circular(2),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(
              color: activeColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // 内部动态扫描线
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: CyberScanline(color: activeColor),
                ),
              ),
              // 按钮文字
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isDisabled)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1500),
                          builder: (context, val, child) {
                            return Opacity(
                              opacity: 0.5 + 0.5 * math.sin(val * math.pi),
                              child: Icon(Icons.chevron_right, color: activeColor, size: fontSize + 4),
                            );
                          },
                        ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: activeColor,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              letterSpacing: width != null && width! < 150 ? 1 : 4,
                              shadows: [
                                Shadow(
                                  color: activeColor.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
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
          ),
        ),
      ),
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: Material(
          color: Colors.transparent,
          child: button,
        ),
      );
    }
    return button;
  }
}

/// 核心旋转装饰 Painter - 中央核心视觉效果
class CyberCenterCorePainter extends CustomPainter {
  final Color color;
  final double pulse;
  CyberCenterCorePainter({required this.color, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 绘制环形
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius * 0.8, ringPaint);
    
    // 绘制旋转刻度
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pulse * 2 * math.pi);
    
    final tickPaint = Paint()
      ..color = color
      ..strokeWidth = 3;

    for (int i = 0; i < 8; i++) {
      canvas.rotate(math.pi / 4);
      canvas.drawLine(Offset(radius * 0.85, 0), Offset(radius * 0.95, 0), tickPaint);
    }
    canvas.restore();

    // 绘制核心
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.1 * (1 + pulse * 0.2), corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 故障风格文本 - 用于加载或处理状态
class CyberGlitchText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const CyberGlitchText({super.key, required this.text, required this.style});

  @override
  State<CyberGlitchText> createState() => _CyberGlitchTextState();
}

class _CyberGlitchTextState extends State<CyberGlitchText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = _random.nextDouble() > 0.8 ? Offset(_random.nextDouble() * 4 - 2, 0) : Offset.zero;
        return Transform.translate(
          offset: offset,
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}

/// 系统返回确认对话框 - 统一的二级确认逻辑
Future<bool> showCyberConfirmExit(BuildContext context, {Color? color}) async {
  final themeColor = color ?? GameProgress.currentNation.themeColor;
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
                          color: themeColor,
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
  return res ?? false;
}

/// 赛博朋克风格扫描线
class CyberScanline extends StatefulWidget {
  final Color color;
  final bool isGlitch;
  const CyberScanline({super.key, required this.color, this.isGlitch = false});

  @override
  State<CyberScanline> createState() => _CyberScanlineState();
}

class _CyberScanlineState extends State<CyberScanline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.isGlitch ? 2 : 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanlinePainter(
            progress: _controller.value,
            color: widget.color,
            isGlitch: widget.isGlitch,
          ),
        );
      },
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isGlitch;

  _ScanlinePainter({
    required this.progress,
    required this.color,
    this.isGlitch = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: isGlitch ? 0.3 : 0.1)
      ..strokeWidth = isGlitch ? 2.0 : 1.0;

    if (isGlitch) {
      final y = progress * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      
      // 添加一些随机的干扰线
      final random = math.Random((progress * 100).toInt());
      for (int i = 0; i < 3; i++) {
        final ry = random.nextDouble() * size.height;
        final rPaint = Paint()
          ..color = color.withValues(alpha: 0.1)
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(0, ry), Offset(size.width, ry), rPaint);
      }
    } else {
      final y = progress * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// 赛博朋克装饰边角
class CyberCornerPainter extends CustomPainter {
  final Color color;
  final double cornerSize;
  final double strokeWidth;

  CyberCornerPainter({
    required this.color,
    this.cornerSize = 20.0,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final actualCornerSize = math.min(cornerSize, math.min(size.width, size.height) / 2);

    // 左上角
    canvas.drawPath(
      Path()
        ..moveTo(0, actualCornerSize)
        ..lineTo(0, 0)
        ..lineTo(actualCornerSize, 0),
      paint,
    );

    // 右上角
    canvas.drawPath(
      Path()
        ..moveTo(size.width - actualCornerSize, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, actualCornerSize),
      paint,
    );

    // 左下角
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - actualCornerSize)
        ..lineTo(0, size.height)
        ..lineTo(actualCornerSize, size.height),
      paint,
    );

    // 右下角
    canvas.drawPath(
      Path()
        ..moveTo(size.width - actualCornerSize, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - actualCornerSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

