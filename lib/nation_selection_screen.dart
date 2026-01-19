import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'level_data.dart';
import 'main.dart';
import 'start_screen.dart';
import 'map_screen.dart';

/// 国度选择界面
class NationSelectionScreen extends StatefulWidget {
  const NationSelectionScreen({super.key});

  @override
  State<NationSelectionScreen> createState() => _NationSelectionScreenState();
}

class _NationSelectionScreenState extends State<NationSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _hoveredNationId;
  late AnimationController _pulseController;
  String? _statusTip;
  Color? _statusTipColor;
  Map<String, Offset>? _positions;
  List<List<String>> _edges = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nations = GameProgress.generatedNations;
    final allCompleted = GameProgress.isAllNationsCompleted();

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
        body: Stack(
          children: [
            const Positioned.fill(child: CyberBackground()),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final positions = _computeLayout(nations, constraints.biggest);
                  final edges = _computeEdges(nations, positions);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _NationMapPainter(
                            nations: nations,
                            hoveredId: _hoveredNationId,
                            pulse: _pulseController,
                            positions: positions,
                            edges: edges,
                          ),
                        ),
                      ),
                      ...nations.map((nation) {
                        final position = positions[nation.id]!;
                        final size = 140.0 * nation.areaScale;
                        return Positioned(
                          left: position.dx - size / 2,
                          top: position.dy - size / 2,
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _hoveredNationId = nation.id),
                            onExit: (_) => setState(() => _hoveredNationId = null),
                            child: GestureDetector(
                              onTap: () => _selectNation(nation),
                              child: Container(
                                width: size,
                                height: size,
                                color: Colors.transparent,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (GameProgress.completedNationIds.contains(nation.id))
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: const Color(0xFF6CE4FF).withValues(alpha: 0.6),
                                          size: 20 * nation.areaScale + 4,
                                        ),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(maxWidth: size),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.center,
                                          child: Text(
                                            nation.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: GameProgress.completedNationIds.contains(nation.id) 
                                                ? const Color(0xFF6CE4FF).withValues(alpha: 0.6) 
                                                : Colors.white.withValues(alpha: 0.8),
                                              fontSize: 10 * nation.areaScale + 2,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                              shadows: const [
                                                Shadow(color: Colors.black, blurRadius: 4),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(nation.difficulty.clamp(1, 5), (i) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 1),
                                            child: Icon(
                                              Icons.star,
                                              size: 8 * nation.areaScale + 2,
                                              color: GameProgress.completedNationIds.contains(nation.id)
                                                  ? Colors.white.withValues(alpha: 0.3)
                                                  : nation.themeColor.withValues(alpha: 0.9),
                                            ),
                                          );
                                        }),
                                      ),
                                      if (GameProgress.completedNationIds.contains(nation.id))
                                        Text(
                                          'SYNCED',
                                          style: TextStyle(
                                            color: const Color(0xFF6CE4FF).withValues(alpha: 0.4),
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            
            // 全通关提示
            if (allCompleted)
              _buildAllCompletedOverlay(),

            // 顶部标题
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    '// SECTOR_SELECTION',
                    style: TextStyle(
                      color: Color(0xFF6CE4FF),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    allCompleted 
                      ? '所有扇区同步完成，系统核心已完全掌控'
                      : '选择目标国度进行数据渗透 (${GameProgress.completedNationIds.length}/${nations.length} 已同步)',
                    style: TextStyle(
                      color: const Color(0xFF6CE4FF).withValues(alpha: 0.6),
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            // 国度详情面板
            if (_hoveredNationId != null && !allCompleted)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: _NationDetailPanel(
                  nation: nations.firstWhere((n) => n.id == _hoveredNationId),
                ),
              ),
            if (_statusTip != null) _statusTipWidget(),
          ],
        ),
      ),
    );
  }

  // 显示游戏状态提示
  void _showStatusTip(String message, Color color) {
    setState(() {
      _statusTip = message;
      _statusTipColor = color;
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _statusTip = null;
        });
      }
    });
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

  Widget _buildAllCompletedOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars, color: Color(0xFF6CE4FF), size: 64),
              const SizedBox(height: 24),
              const Text(
                "MISSION_ACCOMPLISHED",
                style: TextStyle(
                  color: Color(0xFF6CE4FF),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "所有的扇区已完成同步。你已彻底掌控整个网路核心。",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 48),
              CyberButton(
                label: "重启系统 (返回主菜单)",
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 关键区域备注：系统返回二级确认对话框
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
                      const Text(
                        "确认断开连接？",
                        style: TextStyle(
                          color: Color(0xFFFF6A6A),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "尚未选择目标国度，断开连接将返回主菜单。",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF8FA3C0), fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: CyberButton(
                              label: "取消",
                              height: 40,
                              fontSize: 12,
                              color: const Color(0xFF8FA3C0),
                              onPressed: () => Navigator.pop(ctx, false),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CyberButton(
                              label: "断开",
                              height: 40,
                              fontSize: 12,
                              color: const Color(0xFFFF6A6A),
                              onPressed: () => Navigator.pop(ctx, true),
                            ),
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

  Offset _getNationPosition(Nation nation, Size size) {
    final random = math.Random(nation.id.hashCode);
    // 增加一点偏移量，使5-7个国度分布更均匀
    return Offset(
      size.width * (0.15 + random.nextDouble() * 0.7),
      size.height * (0.25 + random.nextDouble() * 0.5),
    );
  }
  Map<String, Offset> _computeLayout(List<Nation> nations, Size size) {
    final positions = <String, Offset>{};
    final cx = size.width * 0.5;
    final cy = size.height * 0.55;
    final count = nations.length;
    final double baseR = math.min(size.width, size.height) * 0.28;
    final double innerR = baseR * 0.56;
    if (count <= 6) {
      for (int i = 0; i < count; i++) {
        final ang = (i / count) * 2 * math.pi;
        positions[nations[i].id] = Offset(
          cx + baseR * math.cos(ang),
          cy + baseR * math.sin(ang),
        );
      }
    } else {
      // 外圈放置 count-3，内圈放置 3
      final outer = count - 3;
      for (int i = 0; i < outer; i++) {
        final ang = (i / outer) * 2 * math.pi;
        positions[nations[i].id] = Offset(
          cx + baseR * math.cos(ang),
          cy + baseR * math.sin(ang),
        );
      }
      for (int j = 0; j < 3; j++) {
        final ang = (j / 3) * 2 * math.pi + math.pi / 6;
        positions[nations[outer + j].id] = Offset(
          cx + innerR * math.cos(ang),
          cy + innerR * math.sin(ang),
        );
      }
    }
    return positions;
  }
  List<List<String>> _computeEdges(List<Nation> nations, Map<String, Offset> pos) {
    final ids = nations.map((n) => n.id).toList();
    final edges = <List<String>>[];
    for (final a in ids) {
      final pa = pos[a]!;
      final neighbors = ids.where((b) => b != a).toList()
        ..sort((b1, b2) => (pos[b1]!-pa).distance.compareTo((pos[b2]!-pa).distance));
      for (int i = 0; i < math.min(2, neighbors.length); i++) {
        final b = neighbors[i];
        final e = [a, b]..sort();
        if (!edges.any((x) => x[0] == e[0] && x[1] == e[1])) edges.add(e);
      }
    }
    return edges;
  }

  void _selectNation(Nation nation) {
    if (GameProgress.completedNationIds.contains(nation.id)) {
      // 如果已通关，显示提示
      _showStatusTip('${nation.title} 已完全同步，请选择其他扇区。', const Color(0xFF6CE4FF));
      return;
    }
    GameProgress.enterNation(nation.id);
    Navigator.push(
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

class _NationMapPainter extends CustomPainter {
  final List<Nation> nations;
  final String? hoveredId;
  final Animation<double> pulse;
  final Map<String, Offset>? positions;
  final List<List<String>> edges;

  _NationMapPainter({
    required this.nations,
    required this.hoveredId,
    required this.pulse,
    required this.positions,
    required this.edges,
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
            colors: [const Color(0x226CE4FF), const Color(0x22FFD700)],
          ).createShader(Rect.fromPoints(a, b))
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(a, b, grad);
      }
    }
    // 使用节点控件呈现国度，不在画布中绘制不规则方块
  }

  void _drawNation(Canvas canvas, Size size, Nation nation) {}

  @override
  bool shouldRepaint(_NationMapPainter oldDelegate) =>
      oldDelegate.hoveredId != hoveredId ||
      oldDelegate.positions != positions ||
      oldDelegate.edges.length != edges.length;
}

class _NationDetailPanel extends StatelessWidget {
  final Nation nation;

  const _NationDetailPanel({required this.nation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: nation.themeColor.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: nation.themeColor.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nation.title.toUpperCase(),
                style: TextStyle(
                  color: nation.themeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              _DifficultyStars(difficulty: nation.difficulty),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nation.description,
            style: const TextStyle(
              color: Color(0xFF8FA3C0),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(label: '预计关卡', value: '${_countLevels(nation)}', color: nation.themeColor),
              const SizedBox(width: 24),
              _StatItem(label: '渗透深度', value: '${nation.layers.length} 层', color: nation.themeColor),
              const Spacer(),
              Text(
                '点击进入国度',
                style: TextStyle(
                  color: nation.themeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _countLevels(Nation nation) {
    int count = 0;
    for (var layer in nation.layers) {
      count += layer.length;
    }
    return count;
  }
}

class _DifficultyStars extends StatelessWidget {
  final int difficulty;

  const _DifficultyStars({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final isActive = index < difficulty;
        return Icon(
          isActive ? Icons.bolt : Icons.bolt_outlined,
          color: isActive ? const Color(0xFFFFD700) : Colors.grey.withValues(alpha: 0.3),
          size: 16,
        );
      }),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
