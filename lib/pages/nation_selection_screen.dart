import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/level_data.dart';
import '../main.dart';
import '../config/theme_config.dart';
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

  PageController? _pageController;
  double _currentPage = 0.0;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _initPageController();
  }
  
  void _initPageController() {
    if (_pageController != null) return;
    
    // 初始位置设为中间某处，实现伪无限滚动
    // 1000 * nations.length 确保有足够的前后滚动空间
    _pageController = PageController(
      viewportFraction: 0.25, 
      initialPage: GameProgress.generatedNations.isEmpty ? 0 : 1000 * GameProgress.generatedNations.length
    );
    _currentPage = _pageController!.initialPage.toDouble();
    
    _pageController!.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController!.page ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 确保 PageController 在构建前已初始化（处理热重载情况）
    if (_pageController == null) {
      _initPageController();
    }
    
    final nations = GameProgress.generatedNations;
    final allCompleted = GameProgress.isAllNationsCompleted();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showCyberConfirmExit(context);
        if (shouldExit && context.mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: CyberBackground()),
            
            // 弧形无限滚动国度列表
            if (nations.isNotEmpty)
              Positioned.fill(
                child: PageView.builder(
                  controller: _pageController!,
                  // 足够大的数量实现无限滚动
                  itemCount: nations.length * 2000, 
                  itemBuilder: (context, index) {
                    // 使用取模运算获取实际的国度索引
                    final nationIndex = index % nations.length;
                    final nation = nations[nationIndex];
                    
                    // 计算相对于当前页面的偏移量 (-1.0 到 1.0 之间为可见区域)
                    final double relativePosition = index - _currentPage;
                    
                    // 计算弧度布局参数
                    // y轴偏移：利用余弦函数制作拱形效果 (中间高，两边低)
                    // 越接近中心(0)，offsetY越小(靠上)
                    final double verticalOffset = 100.0 * (1 - math.cos(relativePosition * 0.8).abs());
                    
                    // 缩放效果：中心大，两边小
                    final double scale = 1.0 - (relativePosition.abs() * 0.2).clamp(0.0, 0.4);
                    
                    // 透明度：边缘淡出
                    final double opacity = (1.0 - relativePosition.abs() * 0.4).clamp(0.0, 1.0);
                    
                    // 旋转角度：根据位置轻微旋转
                    final double rotation = relativePosition * 0.1;

                    const double bannerWidth = 140.0;
                    const double bannerHeight = 220.0;

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // 透视效果
                        ..translate(0.0, verticalOffset + 150.0) // 弧形垂直偏移
                        ..rotateZ(rotation)
                        ..scale(scale),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: opacity,
                        child: Center(
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _hoveredNationId = nation.id),
                            onExit: (_) => setState(() => _hoveredNationId = null),
                            child: GestureDetector(
                              onTap: () => _selectNation(nation),
                              child: CyberNationBanner(
                                nation: nation,
                                width: bannerWidth,
                                height: bannerHeight,
                                isHovered: _hoveredNationId == nation.id,
                                isCompleted: GameProgress.completedNationIds.contains(nation.id),
                              ),
                            ),
                          ),
                        ),
                      ),
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
            // 国度详情面板 - 动态获取当前选中的（最中间的）国度
            if (!allCompleted && nations.isNotEmpty)
              Positioned(
                bottom: 400,
                left: 20,
                right: 20,
                child: _buildCurrentNationDetail(nations),
              ),
            if (_statusTip != null) _statusTipWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentNationDetail(List<Nation> nations) {
    // 获取当前中心位置的国度索引
    final int currentIndex = (_currentPage.round()) % nations.length;
    final currentNation = nations[currentIndex];
    
    // 如果有鼠标悬停，优先显示悬停的，否则显示当前中心的
    final displayNation = _hoveredNationId != null 
        ? nations.firstWhere((n) => n.id == _hoveredNationId, orElse: () => currentNation)
        : currentNation;

    return _NationDetailPanel(nation: displayNation);
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
      label: "// 扇区数据",
      sessionLabel: "编号_${nation.id.toUpperCase()}",
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
              _StatItem(label: '节点数', value: '${_countLevels(nation)}', color: nation.themeColor),
              const SizedBox(width: 32),
              _StatItem(label: '层级深度', value: '${nation.layers.length} 层', color: nation.themeColor),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '状态: 就绪',
                    style: TextStyle(
                      color: nation.themeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    '点击接入',
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

class CyberNationBanner extends StatelessWidget {
  final Nation nation;
  final bool isHovered;
  final bool isCompleted;
  final double width;
  final double height;

  const CyberNationBanner({
    super.key,
    required this.nation,
    required this.isHovered,
    required this.isCompleted,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // 已完成的国度使用金色，未完成使用主题色
    final color = isCompleted ? const Color(0xFFFFD700) : nation.themeColor;
    final double opacity = isCompleted ? 0.9 : (isHovered ? 1.0 : 0.8);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: width,
      height: height,
      transform: Matrix4.identity()..scale(isHovered ? 1.1 : 1.0),
      alignment: Alignment.center, // Ensure transform origin is center
      decoration: BoxDecoration(
        color: color.withValues(alpha: isCompleted ? 0.2 : 0.1),
        border: Border.all(
          color: color.withValues(alpha: isHovered ? 1.0 : 0.6),
          width: isHovered ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          if (isHovered || isCompleted)
            BoxShadow(
              color: color.withValues(alpha: isCompleted ? 0.6 : 0.4),
              blurRadius: isCompleted ? 25 : 15,
              spreadRadius: isCompleted ? 4 : 2,
            ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: isCompleted ? 0.4 : 0.2),
            color.withValues(alpha: isCompleted ? 0.1 : 0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Scanlines or grid background
          Positioned.fill(
            child: CustomPaint(
              painter: _HoloBannerPainter(color: color),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Icon
                Icon(
                  nation.icon,
                  size: 32,
                  color: color.withValues(alpha: opacity),
                ),
                const Spacer(),
                // Name Prefix (Vertical or small)
                Text(
                  nation.namePrefix.toUpperCase(),
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Title
                Text(
                  nation.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCompleted ? const Color(0xFFFFFAE0) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: color, blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Difficulty
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(nation.difficulty, (i) => Icon(
                    Icons.star,
                    size: 10,
                    color: color,
                  )),
                ),
                if (isCompleted) ...[
                  const SizedBox(height: 8),
                  Text(
                    'SYNCED',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoloBannerPainter extends CustomPainter {
  final Color color;
  _HoloBannerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw horizontal scanlines
    for (double y = 0; y < size.height; y += 4) {
      if (y % 8 == 0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
    
    // Corner accents
    final cornerPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    const double len = 10;
    // Top Left
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), cornerPaint);
    
    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
