// map_screen.dart
// 作用：提供树状地图选择界面，用于查看已击败与下一层可挑战的关卡
// 重新设计：更加科幻、清晰的地图显示，突出玩家位置

import 'package:flutter/material.dart';
import 'start_screen.dart';
import 'level_data.dart';
import 'main.dart';
import 'rest_page.dart';
import 'exchange_page.dart';

/// 树状地图页面 - 科幻风格重设计
class MapScreen extends StatefulWidget {
  final bool canReturnToGame;
  final bool canSelect; // 是否允许选择并进入节点
  const MapScreen({
    super.key,
    this.canReturnToGame = false,
    this.canSelect = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  List<List<LevelInfo>> get _layers => levelLayers;
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

    // 计算目标坐标
    // 逻辑与 _buildNodesLayer 中的 spaceEvenly 保持一致
    const double mapWidth = 1000.0;
    const double mapHeight = 1200.0;
    
    final double y = mapHeight * (layerIndex + 1) / (_layers.length + 1);
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
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
          child: Container(
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
                  color: const Color(0xFF6CE4FF).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6CE4FF).withValues(alpha: 0.1),
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
                          color: const Color(0xFF6CE4FF).withValues(alpha: 0.5),
                          fontSize: 7,
                          letterSpacing: 1.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "SEC_LEVEL: ALPHA",
                        style: TextStyle(
                          color: const Color(0xFF6CE4FF).withValues(alpha: 0.5),
                          fontSize: 7,
                          letterSpacing: 1,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hub_outlined,
                        color: Color(0xFF6CE4FF),
                        size: 16,
                      ),
                      SizedBox(width: 12),
                      Text(
                        '全域网络拓扑图',
                        style: TextStyle(
                          color: Color(0xFFE1E9FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 4,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.hub_outlined,
                        color: Color(0xFF6CE4FF),
                        size: 16,
                      ),
                    ],
                  ),
                ],
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
                  height: 1200,
                  child: Stack(
                    children: [
                      // 连接线层
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MapPathPainter(
                            layers: _layers,
                            pulseController: _pulseController,
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
                      label: widget.canSelect ? '退出本次渗透' : '重返渗透节点',
                      onPressed: () async {
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
          for (int i = 0; i < _layers.length; i++)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  _layers[i]
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
    final nodeIndex = levelLayers[layerIndex].indexOf(node);
    final allowedIndices = GameProgress.allowedNextIndices();
    final isAllowed = isNext && allowedIndices.contains(nodeIndex);
    final isCurrent =
        layerIndex == GameProgress.currentLayer &&
        node.id == GameProgress.currentLevelId;

    // 节点颜色方案
    Color glowColor;
    switch (node.type) {
      case 'sync':
        glowColor = const Color(0xFF6CE4FF);
        break;
      case 'exchange':
        glowColor = const Color(0xFFE26CFF);
        break;
      default:
        glowColor = const Color(0xFF6CE4FF);
    }

    final isAccessible = isAllowed || isCurrent;
    final alpha = defeated ? 0.4 : (isAccessible ? 1.0 : 0.3);

    IconData icon;
    switch (node.type) {
      case 'sync':
        icon = Icons.bolt;
        break;
      case 'exchange':
        icon = Icons.hub_outlined;
        break;
      default:
        icon = Icons.terminal_outlined;
    }

    return GestureDetector(
      onTap: () {
        if (!widget.canSelect) {
          CyberToast.show(context, '当前模式仅支持查看拓扑结构');
          return;
        }
        if (isAllowed) {
          // 处理进入新节点
          GameProgress.setCurrentLevel(node);
          
          Widget targetPage;
          if (node.type == 'sync') {
            targetPage = RestPage(levelId: node.id);
          } else if (node.type == 'exchange') {
            targetPage = ExchangePage(levelId: node.id);
          } else {
            targetPage = BattlePage(programIds: node.programIds, levelId: node.id);
          }

          Navigator.pushReplacement(
            context,
            createHoloRoute(targetPage),
          );
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
                  width: 110,
                  height: 110,
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
                width: 90,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0F16).withValues(alpha: 0.8 * alpha),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        isCurrent
                            ? glowColor
                            : glowColor.withValues(alpha: 0.3 * alpha),
                    width: isCurrent ? 1.5 : 1.0,
                  ),
                  boxShadow:
                      isCurrent
                          ? [
                            BoxShadow(
                              color: glowColor.withValues(alpha: 0.3),
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
                          color: glowColor.withValues(alpha: 0.6 * alpha),
                          cornerSize: 12,
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
                          fontSize: 6,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 4,
                      child: Text(
                        "L:${layerIndex} N:${nodeIndex}",
                        style: TextStyle(
                          color: glowColor.withValues(alpha: 0.5 * alpha),
                          fontSize: 6,
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
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
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
                            fontSize: 7,
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
                            fontSize: 8,
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
                        color: const Color(0xFF6CE4FF),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF6CE4FF),
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
                    painter: CyberCornerPainter(color: const Color(0x66FF6A6A)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFF6A6A),
                          size: 20,
                        ),
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
                          color: const Color(0xFF6CE4FF),
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
  return Future.value(res ?? false);
}

/// 科幻风格路径绘制 - 简化清晰
class _MapPathPainter extends CustomPainter {
  final List<List<LevelInfo>> layers;
  final AnimationController pulseController;

  _MapPathPainter({required this.layers, required this.pulseController});

  @override
  void paint(Canvas canvas, Size size) {
    // 获取屏幕尺寸和节点位置
    final layerHeight = size.height / (layers.length + 1);

    // 绘制层间主要路径（简化版：只连接关键节点）
    for (int i = 0; i < layers.length - 1; i++) {
      final currentLayer = layers[i];
      final nextLayer = layers[i + 1];

      // 只绘制主要的连接线，避免错综复杂
      for (int j = 0; j < currentLayer.length && j < nextLayer.length; j++) {
        final nextNode = nextLayer[j];

        final nextDefeated = GameProgress.isDefeated(nextNode.id);
        final nextLayerIndex = i + 1;
        final nextNodeIndex = nextLayer.indexOf(nextNode);
        final allowedIndices = GameProgress.allowedNextIndices();
        final isNext = nextLayerIndex == GameProgress.currentLayer + 1;
        final isNextAccessible =
            isNext && allowedIndices.contains(nextNodeIndex);

        // 路径颜色
        Color pathColor;
        double opacity = 0.3;
        double strokeWidth = 1.5;

        if (nextDefeated) {
          pathColor = const Color(0xFF6CE4FF); // 已完成的路径
          opacity = 0.5;
        } else if (isNextAccessible) {
          pathColor = const Color(0xFF6CE4FF); // 可到达的路径
          opacity = 0.6;
        } else {
          pathColor = const Color(0xFF2A4158); // 未解锁的路径
          opacity = 0.3;
        }

        // 计算节点位置
        final currentX =
            size.width * (0.2 + j * 0.6 / (currentLayer.length - 1));
        final currentY = layerHeight * (i + 1);
        final nextX = size.width * (0.2 + j * 0.6 / (nextLayer.length - 1));
        final nextY = layerHeight * (i + 2);

        final pathPaint =
            Paint()
              ..color = pathColor.withValues(alpha: opacity)
              ..strokeWidth = strokeWidth
              ..style = PaintingStyle.stroke;

        // 绘制贝塞尔曲线路径
        final path = Path()..moveTo(currentX, currentY);

        final controlY = (currentY + nextY) / 2;
        path.cubicTo(currentX, controlY, nextX, controlY, nextX, nextY);

        canvas.drawPath(path, pathPaint);

        // --- 新增：数据流脉冲效果 ---
        if (nextDefeated || isNextAccessible) {
          final pulsePaint =
              Paint()
                ..color = pathColor.withValues(alpha: 0.8)
                ..strokeWidth = 2.5
                ..style = PaintingStyle.fill;

          // 使用 pulseController 实现沿路径移动的小点
          final pathMetrics = path.computeMetrics();
          for (final metric in pathMetrics) {
            // 在一条线上放两个点，交替出现
            for (int k = 0; k < 2; k++) {
              double offsetPercent = (pulseController.value + k * 0.5) % 1.0;
              final tangent = metric.getTangentForOffset(
                metric.length * offsetPercent,
              );
              if (tangent == null) continue;
              final pos = tangent.position;

              canvas.drawCircle(pos, 1.5, pulsePaint);
              // 外层光晕
              final glowPulsePaint =
                  Paint()
                    ..color = pathColor.withValues(alpha: 0.3)
                    ..style = PaintingStyle.fill
                    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
              canvas.drawCircle(pos, 3.0, glowPulsePaint);
            }
          }
        }

        // 可访问路径的发光效果
        if (isNextAccessible && opacity > 0.4) {
          final glowPaint =
              Paint()
                ..color = pathColor.withValues(
                  alpha: 0.15 * pulseController.value,
                )
                ..strokeWidth = strokeWidth + 4
                ..style = PaintingStyle.stroke
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawPath(path, glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MapPathPainter oldDelegate) =>
      oldDelegate.pulseController.value != pulseController.value;
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
          color: const Color(0xFF6CE4FF).withValues(alpha: 0.15),
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
