import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_state.dart';
import 'level_data.dart';
import 'main.dart';
import 'theme_config.dart';
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
  // Map<String, Offset>? _positions;
  // List<List<String>> _edges = [];

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final positions = _computeLayout(nations, constraints.biggest);
        final edges = _computeEdges(nations, positions);
        
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
            body: Stack(
              children: [
                const Positioned.fill(child: CyberBackground()),
                Positioned.fill(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: CyberNationMapPainter(
                              nations: nations,
                              hoveredId: _hoveredNationId,
                              pulse: _pulseController,
                              positions: positions,
                              edges: edges,
                              themeColor: GameState.getThemeColor(),
                            ),
                          ),
                        ),
                      ),
                      ...nations.map((nation) {
                        final position = positions[nation.id]!;
                        const double size = 140.0;
                        return Positioned(
                          left: position.dx - size / 2,
                          top: position.dy - size / 2,
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _hoveredNationId = nation.id),
                            onExit: (_) => setState(() => _hoveredNationId = null),
                            child: GestureDetector(
                              onTap: () => _selectNation(nation),
                              child: RepaintBoundary(
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
                                            color: GameState.getThemeColor().withValues(alpha: 0.6),
                                            size: 24,
                                          ),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: size),
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
                                                  ? GameState.getThemeColor().withValues(alpha: 0.6) 
                                                  : Colors.white.withValues(alpha: 0.8),
                                                fontSize: 12,
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
                                                size: 10,
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
                                              color: GameState.getThemeColor(),
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
                          ),
                        );
                      }),
                    ],
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
                      Text(
                        '// SECTOR_SELECTION',
                        style: TextStyle(
                          color: GameState.getThemeColor(),
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
                          color: GameState.getThemeColor().withValues(alpha: 0.6),
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
      },
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
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
              Icon(Icons.stars, color: GameState.getThemeColor(), size: 64),
              const SizedBox(height: 24),
              Text(
                "MISSION_ACCOMPLISHED",
                style: TextStyle(
                  color: GameState.getThemeColor(),
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
      _showStatusTip('${nation.title} 已完全同步，请选择其他扇区。', GameState.getThemeColor());
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

class _NationDetailPanel extends StatelessWidget {
  final Nation nation;

  const _NationDetailPanel({required this.nation});

  @override
  Widget build(BuildContext context) {
    return CyberLogicPanel(
      color: nation.themeColor,
      label: "// SECTOR_DATA",
      sessionLabel: "UID_${nation.id.toUpperCase()}",
      icon: Icons.analytics_outlined,
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
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
              _DifficultyStars(difficulty: nation.difficulty),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: nation.themeColor.withValues(alpha: 0.05),
              border: Border(left: BorderSide(color: nation.themeColor, width: 2)),
            ),
            child: Text(
              nation.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 20),
          CyberTacticalDivider(color: nation.themeColor),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(label: 'EST_NODES', value: '${_countLevels(nation)}', color: nation.themeColor),
              const SizedBox(width: 32),
              _StatItem(label: 'DEPTH', value: '${nation.layers.length} LAYERS', color: nation.themeColor),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'STATUS: READY',
                    style: TextStyle(
                      color: nation.themeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'TAP_TO_ENGAGE',
                    style: TextStyle(
                      color: nation.themeColor.withValues(alpha: 0.5),
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
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
