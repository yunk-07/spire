// map_screen.dart
// 作用：提供树状地图选择界面，用于查看已击败与下一层可挑战的关卡
// 重新设计：更加科幻、清晰的地图显示，突出玩家位置

import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'game_state.dart';
import 'nation_selection_screen.dart';
import 'start_screen.dart';
import 'level_data.dart';
import 'main.dart';
import 'rest_page.dart';
import 'rest_screen.dart';
import 'exchange_page.dart';
import 'huozhan_page.dart';
import 'xiaotanwei_page.dart';
import 'shangpu_page.dart';
import 'jiaoyidian_page.dart';
import 'shujugui_page.dart';
import 'jiaohuan_zhan_page.dart';
import 'program_data.dart';
import 'campfire_screen.dart';
import 'rest_stop_screen.dart';
import 'maintenance_bay_screen.dart';
import 'cooling_chamber_screen.dart';

/// 树状地图页面 - 科幻风格重设计
class MapScreen extends StatefulWidget {
  final bool canReturnToGame;
  final bool canSelect; // 是否允许选择并进入节点
  final bool isJumpMode; // 是否为时空跳跃模式
  const MapScreen({
    super.key,
    this.canReturnToGame = false,
    this.canSelect = false,
    this.isJumpMode = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  List<List<LevelInfo>> get _layers => GameProgress.levelLayers;
  late AnimationController _pulseController;
  late AnimationController _scanLineController;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // 初始聚焦到玩家当前位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentPosition();
    });
  }

  void _scrollToCurrentPosition() {
    final currentLevelId = GameProgress.currentLevelId;
    int layerIndex = -1;
    int nodeIndex = -1;

    // 查找当前关卡所在位置
    for (int i = 0; i < _layers.length; i++) {
      for (int j = 0; j < _layers[i].length; j++) {
        if (_layers[i][j].id == currentLevelId) {
          layerIndex = i;
          nodeIndex = j;
          break;
        }
      }
      if (layerIndex != -1) break;
    }

    // 如果没找到当前关卡（例如刚开始游戏还没进入第一关），默认看第一层
    if (layerIndex == -1) {
      layerIndex = 0;
      nodeIndex = _layers[0].length ~/ 2;
    }

    // 计算目标坐标（自下而上布局）
    const double mapWidth = 1000.0;
    const double mapHeight = 2400.0;
    final double layerHeight = mapHeight / (_layers.length + 1);
    final double y = mapHeight - layerHeight * (layerIndex + 1);
    final double x = mapWidth * (nodeIndex + 1) / (_layers[layerIndex].length + 1);

    // 获取视口大小以进行居中计算
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final viewportSize = renderBox.size;
      
      // 计算矩阵：平移到中心
      // 注意：InteractiveViewer 的 transform 是应用在 child 上的
      // 目标是将 (x, y) 移动到视口中心 (viewportSize.width/2, viewportSize.height/2)
      final double targetX = -x + viewportSize.width / 2;
      final double targetY = -y + viewportSize.height / 2;

      _transformationController.value = Matrix4.identity()
        ..translate(targetX, targetY);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanLineController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = GameProgress.currentNation.themeColor;
    final isNationFinished = GameProgress.isCurrentNationFinished();
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (isNationFinished) {
          Navigator.pushReplacement(
            context,
            createHoloRoute(const NationSelectionScreen()),
          );
          return;
        }

        // 如果是处于战斗中查看地图（canSelect为false），直接返回战斗
        if (!widget.canSelect) {
          Navigator.pop(context);
        } else {
          // 否则（如胜利后的地图，或初始地图），需要二级确认
          final shouldExit = await _confirmExit(context);
          if (shouldExit && context.mounted) {
            // 返回到开始页面（根路由）
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                    width: 1.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 元数据标签
                    Row(
                      children: [
                        Text(
                          "// TOPOLOGY_MAP_PROTOCOL",
                          style: TextStyle(
                            color: GameState.getThemeColor().withValues(alpha: 0.5),
                            fontSize: 7,
                            letterSpacing: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "SEC_LEVEL: ALPHA",
                          style: TextStyle(
                            color: GameState.getThemeColor().withValues(alpha: 0.5),
                            fontSize: 7,
                            letterSpacing: 1,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hub_outlined,
                          color: themeColor,
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${GameProgress.currentNation.title} 拓扑图',
                          style: const TextStyle(
                            color: Color(0xFFE1E9FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 4,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.hub_outlined,
                          color: themeColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // 关键区域：统一背景美化
            const Positioned.fill(child: CyberBackground()),
            // 新增：漂浮数据装饰层
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _FloatingDataPainter(
                        progress: _pulseController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
            // 地图内容
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformationController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(400),
                minScale: 0.6,
                maxScale: 2.0,
                child: SizedBox(
                  width: 1000,
                  height: 2400,
                  child: Stack(
                    children: [
                      // 连接线层
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MapPathPainter(
                            layers: _layers,
                            pulseController: _pulseController,
                            themeColor: themeColor,
                          ),
                        ),
                      ),
                      // 节点层
                      _buildNodesLayer(),
                    ],
                  ),
                ),
              ),
            ),
            
            // --- 新增：扇区同步成功提示 ---
            if (isNationFinished)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: GameState.getThemeColor().withValues(alpha: 0.1),
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: GameState.getThemeColor().withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "SECTOR_FULLY_SYNCHRONIZED",
                          style: TextStyle(
                            color: GameState.getThemeColor(),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "当前扇区核心已解构，请前往大地图选择下一目标",
                          style: TextStyle(
                            color: GameState.getThemeColor().withValues(alpha: 0.7),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 返回按钮
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                bottom: true,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: CyberButton(
                      heroTag: 'main_action_button',
                      label: isNationFinished 
                        ? '同步完成：前往新扇区' 
                        : (widget.isJumpMode ? '取消跳跃' : (widget.canSelect ? '退出本次渗透' : '重返渗透节点')),
                      onPressed: () async {
                        if (isNationFinished) {
                          Navigator.pushReplacement(
                            context,
                            createHoloRoute(const NationSelectionScreen()),
                          );
                          return;
                        }
                        if (widget.isJumpMode) {
                          Navigator.pop(context);
                          return;
                        }
                        if (!widget.canSelect) {
                          Navigator.pop(context);
                        } else {
                          final shouldExit = await _confirmExit(context);
                          if (shouldExit && context.mounted) {
                            // 返回到开始页面（根路由）
                            Navigator.popUntil(context, (route) => route.isFirst);
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodesLayer() {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = _layers.length - 1; i >= 0; i--)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _layers[i]
                  .map((node) => _nodeWidget(context, node, i))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _nodeWidget(BuildContext context, LevelInfo node, int layerIndex) {
    final defeated = GameProgress.isDefeated(node.id);
    final isNext = layerIndex == GameProgress.currentLayer + 1;
    final nodeIndex = GameProgress.levelLayers[layerIndex].indexOf(node);
    final allowedIndices = GameProgress.allowedNextIndices();
    final isAllowed = isNext && allowedIndices.contains(nodeIndex);
    final isCurrent =
        layerIndex == GameProgress.currentLayer &&
        node.id == GameProgress.currentLevelId;

    // 节点颜色方案
    Color glowColor;
    switch (node.type) {
      case LevelType.infiltration:
        glowColor = GameState.getThemeColor();
        break;
      case LevelType.elite:
        glowColor = const Color(0xFFFF9E6C); // 橙色：精英
        break;
      case LevelType.cache:
        glowColor = const Color(0xFFFFD700); // 金色：缓存站
        break;
      case LevelType.exchange:
        glowColor = const Color(0xFFE26CFF); // 紫色：交易所
        break;
      case LevelType.mystery:
        glowColor = const Color(0xFFB0B0B0); // 银灰色：未知
        break;
      case LevelType.rest:
        glowColor = const Color(0xFF6CFF9E); // 青绿色：休息站
        break;
      case LevelType.boss:
        glowColor = const Color(0xFFFF4D4D); // 红色：核心
        break;
    }

    final int difficulty = node.difficulty.clamp(1, 5);
    late final Color diffColor;
    switch (difficulty) {
      case 1:
        diffColor = const Color(0xFF44FF44);
        break;
      case 2:
        diffColor = GameState.getThemeColor();
        break;
      case 3:
        diffColor = const Color(0xFFE26CFF);
        break;
      case 4:
        diffColor = const Color(0xFFFFD700);
        break;
      default:
        diffColor = const Color(0xFFFF4444);
        break;
    }
    final isAccessible = isAllowed || isCurrent || (widget.isJumpMode && !defeated);
    final alpha = defeated ? 0.4 : (isAccessible ? 1.0 : 0.3);

    IconData icon;
    switch (node.type) {
      case LevelType.infiltration:
        icon = Icons.terminal_outlined;
        break;
      case LevelType.elite:
        icon = Icons.warning_outlined;
        break;
      case LevelType.cache:
        icon = Icons.battery_charging_full_outlined;
        break;
      case LevelType.exchange:
        icon = Icons.hub_outlined;
        break;
      case LevelType.mystery:
        icon = Icons.help_outline;
        break;
      case LevelType.rest:
        icon = Icons.healing_outlined;
        break;
      case LevelType.boss:
        icon = Icons.security_outlined;
        break;
    }

    return GestureDetector(
      onTap: () {
        if (!widget.canSelect) {
          CyberToast.show(context, '当前模式仅支持查看拓扑结构');
          return;
        }

        // 时空跳跃逻辑：可以选择任何未去过的节点
        final bool canJump = widget.isJumpMode && !defeated && !isCurrent;
        
        if (isAllowed || canJump) {
          _showLevelPreview(context, node, layerIndex);
        } else if (isCurrent) {
          CyberToast.show(context, '当前正处于此渗透节点');
        } else if (defeated) {
          CyberToast.show(context, '该节点已完成渗透');
        } else {
          CyberToast.show(context, '该节点目前无法接入，请先完成前置渗透');
        }
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          double glowIntensity =
              isCurrent ? (1.0 + _pulseController.value * 0.4) : 1.0;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. 玩家位置的大光晕
              if (isCurrent)
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        glowColor.withValues(alpha: 0.2 * glowIntensity),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

              // 2. 节点主体
              Container(
                width: 110,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0F16).withValues(alpha: 0.8 * alpha),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isCurrent
                        ? Color.lerp(glowColor, diffColor, 0.5)!
                        : Color.lerp(glowColor.withValues(alpha: 0.3 * alpha), diffColor.withValues(alpha: 0.6 * alpha), 0.5)!,
                    width: isCurrent ? 1.5 : 1.0,
                  ),
                  boxShadow:
                      isCurrent
                          ? [
                            BoxShadow(
                              color: Color.lerp(glowColor, diffColor, 0.4)!.withValues(alpha: 0.4),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ]
                          : [],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 内部扫描线
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Opacity(
                          opacity: alpha,
                          child: CyberScanline(
                            color: glowColor.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
                    // 装饰边角
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CyberCornerPainter(
                          color: Color.lerp(glowColor, diffColor, 0.5)!.withValues(alpha: 0.6 * alpha),
                          cornerSize: 10 + difficulty * 2,
                        ),
                      ),
                    ),
                    // --- 新增：节点元数据装饰 ---
                    Positioned(
                      top: 2,
                      left: 4,
                      child: Text(
                        "ID: ${node.id.substring(0, 4).toUpperCase()}",
                        style: TextStyle(
                          color: glowColor.withValues(alpha: 0.5 * alpha),
                          fontSize: 9,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 4,
                      child: Text(
                        "L:$layerIndex N:$nodeIndex",
                        style: TextStyle(
                          color: glowColor.withValues(alpha: 0.5 * alpha),
                          fontSize: 9,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    // --- 节点内容 ---
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            color:
                                defeated
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : glowColor.withValues(alpha: 0.9 * alpha),
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            node.title.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  defeated
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.white.withValues(
                                        alpha: 0.9 * alpha,
                                      ),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(node.difficulty.clamp(1, 5), (i) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1),
                                child: Icon(
                                  Icons.star,
                                  size: 8,
                                  color: defeated
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : diffColor.withValues(alpha: 0.95 * alpha),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    // 当前位置动态标记
                    if (isCurrent)
                      Positioned(
                        bottom: 2,
                        left: 4,
                        child: Text(
                          "LINKED",
                          style: TextStyle(
                            color: glowColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 3. 状态标识
              if (isCurrent)
                Positioned(
                  top: -12,
                  child: Transform.scale(
                    scale: 1.0 + _pulseController.value * 0.1,
                    child: Opacity(
                      opacity: 0.8 + _pulseController.value * 0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: glowColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Text(
                          "ACTIVE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              if (defeated && !isCurrent)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0F16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: GameState.getThemeColor(),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: GameState.getThemeColor(),
                      size: 10,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showLevelPreview(BuildContext context, LevelInfo node, int layerIndex) {
    final color = GameState.getThemeColor();
    final nextLayer = layerIndex + 1 < _layers.length ? _layers[layerIndex + 1] : const <LevelInfo>[];
    final nextTitles = nextLayer.where((lvl) => node.nextLevelIndices.contains(nextLayer.indexOf(lvl))).map((e) => e.title).toList();
    final monsterNames = node.programIds.map((id) => systemDatabase[id]?.name ?? id).toList();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "LEVEL_PREVIEW",
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, a1, a2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 420,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0F16).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 18, spreadRadius: 2)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.map_outlined, color: color, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(node.title, softWrap: true, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1))),
                              _difficultyStars(node.difficulty),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text("// LEVEL_CONFIRM", style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 9, fontFamily: 'monospace', letterSpacing: 2)),
                              const Spacer(),
                              Text("ID:${node.id}", style: TextStyle(color: const Color(0xFF8FA3C0), fontSize: 10, fontFamily: 'monospace')),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (monsterNames.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.05),
                                border: Border(left: BorderSide(color: color.withValues(alpha: 0.4), width: 2)),
                              ),
                              child: Text("可能出现的怪兽：\n${monsterNames.join('、')}", softWrap: true, style: const TextStyle(color: Color(0xFFE1E9FF), fontSize: 12)),
                            ),
                          const SizedBox(height: 8),
                          if (nextTitles.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.05),
                                border: Border(left: BorderSide(color: color.withValues(alpha: 0.4), width: 2)),
                              ),
                              child: Text("可能出现的下一节点：\n${nextTitles.join('、')}", softWrap: true, style: const TextStyle(color: Color(0xFFE1E9FF), fontSize: 12)),
                            ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: CyberButton(
                                  label: '取消',
                                  height: 40,
                                  fontSize: 12,
                                  color: const Color(0xFF8FA3C0),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CyberButton(
                                  label: '进入',
                                  height: 40,
                                  fontSize: 12,
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _enterLevel(node);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CyberScanline(color: color.withValues(alpha: 0.07)),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: CyberCornerPainter(color: color.withValues(alpha: 0.4), cornerSize: 12),
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

  Widget _difficultyStars(int difficulty) {
    return Row(
      children: List.generate(5, (i) {
        final active = i < difficulty;
        return Icon(active ? Icons.star : Icons.star_border, size: 14, color: active ? const Color(0xFFFFD700) : const Color(0xFF3A3F4C));
      }),
    );
  }

  void _enterLevel(LevelInfo node) {
    if (widget.isJumpMode && GameProgress.currentLevelId != null) {
      GameProgress.markDefeated(GameProgress.currentLevelId!);
    }
    GameProgress.setCurrentLevel(node);
    Widget targetPage;
    switch (node.type) {
      case LevelType.cache:
        targetPage = RestPage(levelId: node.id);
        break;
      case LevelType.rest:
        if (node.title.contains('篝火处')) {
          targetPage = CampfireScreen(levelId: node.id);
        } else if (node.title.contains('歇脚点')) {
          targetPage = RestStopScreen(levelId: node.id);
        } else if (node.title.contains('修复站')) {
          targetPage = RestScreen(levelId: node.id);
        } else if (node.title.contains('维保处')) {
          targetPage = MaintenanceBayScreen(levelId: node.id);
        } else if (node.title.contains('冷却间')) {
          targetPage = CoolingChamberScreen(levelId: node.id);
        } else {
          targetPage = RestScreen(levelId: node.id);
        }
        break;
      case LevelType.exchange:
        if (node.title.contains('货栈')) {
          targetPage = HuozhanPage(levelId: node.id);
        } else if (node.title.contains('小摊位')) {
          targetPage = XiaotanweiPage(levelId: node.id);
        } else if (node.title.contains('商铺')) {
          targetPage = ShangpuPage(levelId: node.id);
        } else if (node.title.contains('交易点')) {
          targetPage = JiaoyidianPage(levelId: node.id);
        } else if (node.title.contains('数据柜')) {
          targetPage = ShujuguiPage(levelId: node.id);
        } else if (node.title.contains('交换站')) {
          targetPage = JiaohuanZhanPage(levelId: node.id);
        } else {
          targetPage = ExchangePage(levelId: node.id);
        }
        break;
      case LevelType.mystery:
        final r = Random().nextDouble();
        if (r < 0.4) {
          targetPage = BattlePage(programIds: node.programIds, levelId: node.id);
        } else if (r < 0.7) {
          targetPage = RestScreen(levelId: node.id);
        } else {
          targetPage = ExchangePage(levelId: node.id);
        }
        break;
      default:
        targetPage = BattlePage(programIds: node.programIds, levelId: node.id);
    }
    Navigator.pushReplacement(context, createHoloRoute(targetPage));
  }
}

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
                    painter: CyberCornerPainter(
                      color: const Color(0xFFFF6A6A).withValues(alpha: 0.4),
                      cornerSize: 15,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "确认断开物理接入？",
                      style: TextStyle(
                        color: Color(0xFFFF6A6A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '即将终止当前的渗透任务，未同步的数据流将会丢失。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8FA3C0),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: CyberButton(
                            label: '维持接入',
                            height: 40,
                            fontSize: 12,
                            color: const Color(0xFF8FA3C0),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CyberButton(
                            label: '确认断开',
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

/// 科幻风格路径绘制 - 简化清晰
class _MapPathPainter extends CustomPainter {
  final List<List<LevelInfo>> layers;
  final AnimationController pulseController;
  final Color themeColor;

  _MapPathPainter({
    required this.layers,
    required this.pulseController,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final layerHeight = size.height / (layers.length + 1);

    for (int i = 0; i < layers.length - 1; i++) {
      final currentLayer = layers[i];
      final nextLayer = layers[i + 1];

      for (int j = 0; j < currentLayer.length; j++) {
        final currentNode = currentLayer[j];
        
        // 获取当前节点连向下一层的所有索引
        for (final nextIdx in currentNode.nextLevelIndices) {
          if (nextIdx >= nextLayer.length) continue;
          
          final nextNode = nextLayer[nextIdx];
          
          // 判定逻辑
          final isCurrentLayerActive = i == GameProgress.currentLayer;
          final isCurrentNodeActive = isCurrentLayerActive && currentNode.id == GameProgress.currentLevelId;
          final isNextAccessible = isCurrentNodeActive;
          final isPathDefeated = GameProgress.isDefeated(currentNode.id) && GameProgress.isDefeated(nextNode.id);

          // 路径颜色
          Color pathColor;
          double opacity = 0.3;
          double strokeWidth = 1.5;

          if (isPathDefeated) {
            pathColor = themeColor;
            opacity = 0.6;
          } else if (isNextAccessible) {
            pathColor = themeColor;
            opacity = 0.8;
            strokeWidth = 2.0;
          } else {
            pathColor = const Color(0xFF2A4158);
            opacity = 0.3;
          }

          // 计算精确位置：从下往上的纵向层
          final currentY = size.height - layerHeight * (i + 1);
          final nextY = size.height - layerHeight * (i + 2);
          final currentX = size.width * (j + 1) / (currentLayer.length + 1);
          final nextX = size.width * (nextIdx + 1) / (nextLayer.length + 1);

          final pathPaint = Paint()
            ..color = pathColor.withValues(alpha: opacity)
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke;

          final path = Path()..moveTo(currentX, currentY);
          final controlY = (currentY + nextY) / 2;
          path.cubicTo(currentX, controlY, nextX, controlY, nextX, nextY);

          canvas.drawPath(path, pathPaint);

          // 数据流脉冲
          if (isPathDefeated || isNextAccessible) {
            final pulsePaint = Paint()
              ..color = pathColor.withValues(alpha: 0.8)
              ..strokeWidth = 2.5
              ..style = PaintingStyle.fill;

            final pathMetrics = path.computeMetrics();
            for (final metric in pathMetrics) {
              for (int k = 0; k < 2; k++) {
                double offsetPercent = (pulseController.value + k * 0.5) % 1.0;
                final tangent = metric.getTangentForOffset(metric.length * offsetPercent);
                if (tangent == null) continue;
                final pos = tangent.position;
                canvas.drawCircle(pos, 1.5, pulsePaint);
              }
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MapPathPainter oldDelegate) =>
      oldDelegate.pulseController.value != pulseController.value ||
      oldDelegate.themeColor != themeColor;
}

/// 漂浮的数据装饰效果
class _FloatingDataPainter extends CustomPainter {
  final double progress;
  _FloatingDataPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

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
          color: GameState.getThemeColor().withValues(alpha: 0.15),
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
  bool shouldRepaint(covariant _FloatingDataPainter oldDelegate) => true;
}
