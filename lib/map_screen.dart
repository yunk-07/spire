// map_screen.dart
// 作用：提供树状地图选择界面，用于查看已击败与下一层可挑战的关卡
// 重新设计：更加科幻、清晰的地图显示，突出玩家位置

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_state.dart';
import 'nation_selection_screen.dart';
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
import 'theme_config.dart';
import 'program_data.dart';
import 'character_data.dart';
import 'campfire_screen.dart';
import 'rest_stop_screen.dart';
import 'maintenance_bay_screen.dart';
import 'cooling_chamber_screen.dart';
import 'casino_screen.dart';

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

  Widget _hudStatusItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 7,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border(left: BorderSide(color: color, width: 2)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
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
          final shouldExit = await showCyberConfirmExit(context);
          if (shouldExit && context.mounted) {
            // 返回到开始页面（根路由）
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
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
                    const Color(0xFF101722).withValues(alpha: 0.98),
                    const Color(0xFF0A0F16).withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: themeColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 元数据标签
                    Row(
                      children: [
                        _hudStatusItem("MAP_PROTOCOL", "V4.2.0", themeColor),
                        const SizedBox(width: 16),
                        _hudStatusItem("OPERATOR", characterDatabase[GameState.selectedCharacterId]?.name ?? "UNKNOWN", themeColor),
                        const SizedBox(width: 16),
                        _hudStatusItem("ITG", "${GameState.playerHp}/${GameState.playerMaxHp}", GameState.playerHp / GameState.playerMaxHp < 0.3 ? Colors.redAccent : themeColor),
                        const SizedBox(width: 16),
                        _hudStatusItem("CREDITS", GameState.playerGold.toString(), const Color(0xFFFFD700)),
                        const Spacer(),
                        _hudStatusItem("LOC_NODE", GameProgress.currentLevelId?.substring(0, 8) ?? "N/A", themeColor),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // 背景装饰
                        Container(
                          height: 32,
                          width: 300,
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.05),
                            border: Border.symmetric(
                              vertical: BorderSide(color: themeColor.withValues(alpha: 0.3), width: 1),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 2000),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: 0.3 + 0.7 * (0.5 + 0.5 * math.sin(value * math.pi * 2)),
                                  child: Icon(Icons.radar, color: themeColor, size: 18),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${GameProgress.currentNation.title} 拓扑架构图',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 6,
                                fontFamily: 'monospace',
                                shadows: [
                                  Shadow(color: Colors.blueAccent, blurRadius: 10),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 2000),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: 0.3 + 0.7 * (0.5 + 0.5 * math.cos(value * math.pi * 2)),
                                  child: Icon(Icons.radar, color: themeColor, size: 18),
                                );
                              },
                            ),
                          ],
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
            // 新增：拓扑背景装饰 (网格与数据点)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CyberTopologyBackgroundPainter(
                    themeColor: themeColor,
                  ),
                ),
              ),
            ),
            // 新增：漂浮数据装饰层
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: CyberFloatingDataPainter(
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
                          painter: CyberMapPathPainter(
                            layers: _layers,
                            pulseProgress: _pulseController.value,
                            themeColor: themeColor,
                            currentLayer: GameProgress.currentLayer,
                            currentLevelId: GameProgress.currentLevelId,
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
                          final shouldExit = await showCyberConfirmExit(context);
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
      case LevelType.casino:
        glowColor = const Color(0xFFFFA000); // 琥珀色：赌场
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
      case LevelType.casino:
        icon = Icons.casino_outlined;
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (isCurrent ? glowColor : const Color(0xFF0A0F16)).withValues(alpha: 0.15 * alpha),
                      const Color(0xFF0A0F16).withValues(alpha: 0.8 * alpha),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    bottomRight: Radius.circular(16),
                  ),
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
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 内部扫描线
                    Positioned.fill(
                      child: Opacity(
                        opacity: alpha * 0.15,
                        child: CyberScanline(
                          color: glowColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    // 装饰边角 (仅在未完成或当前时显示更明显)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CyberCornerPainter(
                          color: Color.lerp(glowColor, diffColor, 0.5)!.withValues(alpha: (isCurrent ? 0.8 : 0.4) * alpha),
                          cornerSize: 8.0 + difficulty,
                        ),
                      ),
                    ),
                    // --- 节点元数据装饰 ---
                    Positioned(
                      top: 4,
                      left: 6,
                      child: Text(
                        "UID.${node.id.substring(0, 4).toUpperCase()}",
                        style: TextStyle(
                          color: (isCurrent ? Colors.white : glowColor).withValues(alpha: 0.4 * alpha),
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 6,
                      child: Text(
                        "SEC_L${layerIndex}_N$nodeIndex",
                        style: TextStyle(
                          color: (isCurrent ? Colors.white : glowColor).withValues(alpha: 0.4 * alpha),
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
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
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : glowColor.withValues(alpha: 0.9 * alpha),
                            size: 24,
                            shadows: isCurrent ? [
                              Shadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 8)
                            ] : [],
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
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                              shadows: isCurrent ? [
                                Shadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 4)
                              ] : [],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 难度指示器：点状代替星状更科幻
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              final active = i < node.difficulty.clamp(1, 5);
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active 
                                    ? (defeated ? Colors.white24 : diffColor.withValues(alpha: 0.8 * alpha))
                                    : Colors.white10,
                                  boxShadow: active && isCurrent ? [
                                    BoxShadow(color: diffColor.withValues(alpha: 0.5), blurRadius: 2)
                                  ] : [],
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
                        bottom: 4,
                        left: 6,
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: glowColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "SYNCING",
                              style: TextStyle(
                                color: glowColor,
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 3. 状态标识
              if (isCurrent)
                Positioned(
                  top: -14,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 1.0 + 0.05 * math.sin(value * math.pi * 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [glowColor, glowColor.withValues(alpha: 0.7)],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              bottomRight: Radius.circular(8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Text(
                            "CURRENT_POS",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              if (defeated && !isCurrent)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0F16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: GameState.getThemeColor().withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GameState.getThemeColor().withValues(alpha: 0.2),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      color: GameState.getThemeColor(),
                      size: 12,
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
    final monsters = node.programIds.map((id) => systemDatabase[id]).whereType<SecurityProgram>().toList();
    final nextTitles = nextLayer.where((lvl) => node.nextLevelIndices.contains(nextLayer.indexOf(lvl))).map((e) => e.title).toList();
    
    // 确保标题、侦测到的实体等信息不为空，并添加默认提示
    final displayNextTitles = nextTitles.isEmpty ? ["路径终点或未知区域"] : nextTitles;

    String typeDescription = "";
    IconData typeIcon = Icons.hub_outlined;
    switch (node.type) {
      case LevelType.infiltration:
        typeDescription = "基础数据渗透点。通过击败驻守程序，你可以获取底层架构的访问权限并上传补给。";
        typeIcon = Icons.terminal_outlined;
        break;
      case LevelType.elite:
        typeDescription = "高价值数据节点。此处由精英防火墙程序守护，危险系数极高，但成功渗透后将获得稀有的系统补丁。";
        typeIcon = Icons.warning_outlined;
        break;
      case LevelType.cache:
        typeDescription = "无主数据缓存站。你可以从中直接提取未加密的数据包、补给品或系统增强模块。";
        typeIcon = Icons.battery_charging_full_outlined;
        break;
      case LevelType.exchange:
        typeDescription = "非法数据交易所。利用收集到的加密碎片，在此处与中立程序交换各类战术插件与硬件升级。";
        typeIcon = Icons.hub_outlined;
        break;
      case LevelType.mystery:
        typeDescription = "时空扰动区域。该节点的底层代码极不稳定，可能遭遇意外的机遇，也可能陷入未知的陷阱。";
        typeIcon = Icons.help_outline;
        break;
      case LevelType.rest:
        typeDescription = "逻辑修复中继站。在安全的子网环境中执行逻辑重构，修复受损的硬件外壳或优化现有模块。";
        typeIcon = Icons.healing_outlined;
        break;
      case LevelType.boss:
        typeDescription = "国度核心节点。高塔的关键架构所在地，彻底击毁此处的守卫程序以完成该国度的渗透任务。";
        typeIcon = Icons.security_outlined;
        break;
      case LevelType.casino:
        typeDescription = "地下电子赌场。在这里你可以参与“21点”协议博弈，通过运气与计算赢取更多金币，但也可能倾家荡产。";
        typeIcon = Icons.casino_outlined;
        break;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "LEVEL_PREVIEW",
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, a1, a2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
              child: FadeTransition(
                opacity: a1,
                child: CyberLogicPanel(
                  color: color,
                  maxWidth: 420,
                  label: "// TACTICAL_BRIEFING",
                  sessionLabel: "L${layerIndex}_N${_layers[layerIndex].indexOf(node)}",
                  icon: typeIcon,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题与难度
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  node.title.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _difficultyStars(node.difficulty),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(typeIcon, color: color, size: 32),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 任务简报
                      CyberTacticalDivider(color: color, label: "系统简报"),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(4),
                          border: Border(left: BorderSide(color: color, width: 2)),
                        ),
                        child: Text(
                          typeDescription,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 威胁评估 (怪物)
                      CyberTacticalDivider(color: color, label: "威胁评估"),
                      const SizedBox(height: 12),
                      if (monsters.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            "NO_THREAT_DETECTED (未检测到敌对程序)",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontFamily: 'monospace'),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: monsters.map((m) => _buildMonsterChip(m, color)).toList(),
                        ),
                      const SizedBox(height: 24),

                      // 拓扑预测
                      CyberTacticalDivider(color: color, label: "拓扑预测"),
                      const SizedBox(height: 12),
                      CyberInfoRow(
                        label: "NEXT_NODES",
                        value: displayNextTitles.join(' / '),
                        color: color,
                        icon: Icons.alt_route_outlined,
                      ),
                      const SizedBox(height: 32),

                      // 操作按钮
                      Row(
                        children: [
                          Expanded(
                            child: CyberButton(
                              label: '放弃',
                              height: 48,
                              fontSize: 14,
                              color: const Color(0xFF8FA3C0),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CyberButton(
                              label: '开始渗透',
                              height: 48,
                              fontSize: 14,
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
          ),
        );
      },
    );
  }

  Widget _buildMonsterChip(SecurityProgram m, Color color) {
    IconData typeIcon;
    Color typeColor;
    String typeTag;
    
    switch (m.type) {
      case SystemType.boss:
        typeIcon = Icons.dangerous;
        typeColor = const Color(0xFFFF5252);
        typeTag = "CRITICAL";
        break;
      case SystemType.elite:
        typeIcon = Icons.security;
        typeColor = const Color(0xFFFFD740);
        typeTag = "ELITE";
        break;
      case SystemType.normal:
        typeIcon = Icons.bug_report;
        typeColor = color.withValues(alpha: 0.8);
        typeTag = "NORMAL";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: typeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(typeIcon, color: typeColor, size: 12),
              const SizedBox(width: 6),
              Text(
                m.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  typeTag,
                  style: TextStyle(color: typeColor, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.favorite, color: Colors.red.withValues(alpha: 0.7), size: 10),
              const SizedBox(width: 2),
              Text(
                "${m.maxHp}",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontFamily: 'monospace'),
              ),
              const SizedBox(width: 8),
              Icon(Icons.bolt, color: Colors.amber.withValues(alpha: 0.7), size: 10),
              const SizedBox(width: 2),
              Text(
                "${m.baseDamage}",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _difficultyStars(int difficulty) {
    // 根据难度选择颜色
    Color diffColor;
    if (difficulty <= 1) {
      diffColor = const Color(0xFF44FF44);
    } else if (difficulty == 2) {
      diffColor = GameState.getThemeColor();
    } else if (difficulty == 3) {
      diffColor = const Color(0xFFE26CFF);
    } else if (difficulty == 4) {
      diffColor = const Color(0xFFFFD700);
    } else {
      diffColor = const Color(0xFFFF4444);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final active = i < difficulty;
        final color = active ? diffColor : const Color(0xFF3A3F4C);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(1),
              bottomRight: Radius.circular(3),
            ),
            boxShadow: active ? [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)
            ] : [],
          ),
        );
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
        targetPage = RestPage(level: node);
        break;
      case LevelType.rest:
        if (node.title.contains('篝火处')) {
          targetPage = CampfireScreen(level: node);
        } else if (node.title.contains('歇脚点')) {
          targetPage = RestStopScreen(level: node);
        } else if (node.title.contains('修复站')) {
          targetPage = RestScreen(level: node);
        } else if (node.title.contains('维保处')) {
          targetPage = MaintenanceBayScreen(level: node);
        } else if (node.title.contains('冷却间')) {
          targetPage = CoolingChamberScreen(level: node);
        } else {
          targetPage = RestScreen(level: node);
        }
        break;
      case LevelType.exchange:
        if (node.title.contains('货栈')) {
          targetPage = HuozhanPage(level: node);
        } else if (node.title.contains('小摊位')) {
          targetPage = XiaotanweiPage(level: node);
        } else if (node.title.contains('商铺')) {
          targetPage = ShangpuPage(level: node);
        } else if (node.title.contains('交易点')) {
          targetPage = JiaoyidianPage(level: node);
        } else if (node.title.contains('数据柜')) {
          targetPage = ShujuguiPage(level: node);
        } else if (node.title.contains('交换站')) {
          targetPage = JiaohuanZhanPage(level: node);
        } else {
          targetPage = ExchangePage(level: node);
        }
        break;
      case LevelType.mystery:
        final r = math.Random().nextDouble();
        if (r < 0.4) {
          targetPage = BattlePage(programIds: node.programIds, levelId: node.id);
        } else if (r < 0.7) {
          targetPage = RestScreen(level: node);
        } else {
          targetPage = ExchangePage(level: node);
        }
        break;
      case LevelType.casino:
        if (GameState.playerGold < 20) {
          _showCasinoNoMoneyDialog(node);
          return;
        }
        targetPage = CasinoScreen(level: node);
        break;
      default:
        targetPage = BattlePage(programIds: node.programIds, levelId: node.id);
    }
    Navigator.pushReplacement(context, createHoloRoute(targetPage));
  }

  void _showCasinoNoMoneyDialog(LevelInfo node) async {
    final confirm = await showCyberConfirmExit(
      context,
      color: Colors.redAccent,
      title: "访问受限",
      content: "赌场经理：\"站住！这里的入场费是 20 金币。检测到你的信用分和余额严重不足。\"\n\n\"没有钱就滚出我的地盘，否则安保程序会让你死得很惨。\"",
      cancelLabel: "撤退",
      confirmLabel: "强行闯入",
    );

    if (confirm == true && mounted) {
      // 强行闯入：进入 Boss 战
      Navigator.pushReplacement(
        context,
        createHoloRoute(BattlePage(programIds: ["casino_boss"], levelId: node.id)),
      );
    }
  }
}
