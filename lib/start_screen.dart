import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'character_data.dart';
import 'level_data.dart';
import 'main.dart';
import 'map_screen.dart';
import 'game_state.dart';

/// 赛博朋克风格扫描线
class CyberScanline extends StatefulWidget {
  final Color color;
  final bool isGlitch;
  const CyberScanline({required this.color, this.isGlitch = false});

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
  _ScanlinePainter({required this.progress, required this.color, this.isGlitch = false});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random();
    final glitchOffset = isGlitch ? (random.nextDouble() - 0.5) * 5 : 0.0;
    
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color.withValues(alpha: isGlitch ? 0.3 : 0.1),
          color.withValues(alpha: isGlitch ? 0.15 : 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, size.height * progress - 50 + glitchOffset, size.width, 100));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 绘制极细的横线
    final linePaint = Paint()
      ..color = color.withValues(alpha: isGlitch ? 0.4 : 0.2)
      ..strokeWidth = isGlitch ? 1.0 : 0.5;
    
    double y = size.height * progress + glitchOffset;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    
    if (isGlitch && random.nextDouble() > 0.8) {
      // 额外故障横线
      final gy = random.nextDouble() * size.height;
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), linePaint..color = color.withValues(alpha: 0.1));
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) => true;
}

/// 赛博朋克装饰背景
class CyberBackground extends StatelessWidget {
  const CyberBackground({super.key});

  @override
  Widget build(BuildContext context) {
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
            painter: _BackgroundGridPainter(),
          ),
        ),
        // 扫描线
        const Positioned.fill(
          child: CyberScanline(color: Color(0xFF6CE4FF)),
        ),
      ],
    );
  }
}

class _BackgroundGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6CE4FF).withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
                        color: const Color(0xFF6CE4FF).withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6CE4FF).withValues(alpha: 0.3),
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
                              color: const Color(0xFF6CE4FF).withValues(alpha: 0.5),
                              cornerSize: 8,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF6CE4FF),
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

class _HoloGridPainter extends CustomPainter {
  final double progress;

  _HoloGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.05) {
      return;
    }
    final p = progress.clamp(0.0, 1.0);

    double regionLeft;
    double regionRight;
    if (p < 0.7) {
      final appear = p / 0.7;
      regionLeft = 0;
      regionRight = size.width * appear;
    } else {
      final disappear = (p - 0.7) / 0.3;
      regionLeft = size.width * disappear;
      regionRight = size.width;
    }

    if (regionRight <= regionLeft) {
      return;
    }

    final gridColor = const Color(0x336CE4FF);
    final gridPaint =
        Paint()
          ..color = gridColor
          ..strokeWidth = 1;

    const cell = 16.0;
    for (double x = regionLeft; x <= regionRight; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(regionLeft, y), Offset(regionRight, y), gridPaint);
    }

    const bandWidth = 24.0;
    final bandLeft = (regionRight - bandWidth).clamp(regionLeft, regionRight);
    final bandRight = regionRight;
    if (bandRight <= bandLeft) {
      return;
    }
    final bandRect = Rect.fromLTRB(bandLeft, 0, bandRight, size.height);
    final bandPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0x006CE4FF), Color(0x446CE4FF)],
          ).createShader(bandRect);
    canvas.drawRect(bandRect, bandPaint);
  }

  @override
  bool shouldRepaint(covariant _HoloGridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 赛博朋克风格按钮
class CyberButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final Color color;
  final double fontSize;
  final String? heroTag;

  const CyberButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width = 240,
    this.height = 50,
    this.fontSize = 14,
    this.color = const Color(0xFF6CE4FF),
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;
    final Color activeColor = isDisabled ? Colors.grey : color;

    Widget button = Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F16).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: activeColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 装饰性斜切角
              Positioned(
                top: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(height * 0.24, height * 0.24),
                  painter: _CornerPainter(color: activeColor),
                ),
              ),
              // 按钮文字
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: activeColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: width != null && width! < 150 ? 1 : 4,
                      shadows: [
                        Shadow(
                          color: activeColor.withValues(alpha: 0.5),
                          blurRadius: 4,
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

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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

/// 开始页面 - 欢迎界面
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 关键区域：背景美化
          const Positioned.fill(
            child: CyberBackground(),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 游戏标题
                const Text(
                  'SPIRE',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6CE4FF),
                    letterSpacing: 8.0,
                  ),
                ),
                const SizedBox(height: 20),

                // 游戏副标题
                const Text(
                  'DATA WORLD INFILTRATION SYSTEM',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8FA3C0),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 60),

                // 开始游戏按钮
                CyberButton(
                  heroTag: 'main_action_button',
                  label: '初始化接入序列',
                  onPressed: () {
                    Navigator.push(
                      context,
                      createHoloRoute(const CharacterSelectScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 游戏说明
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: const Text(
                    '选择接入单元，上传记忆与战术模块，执行高塔渗透任务。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF5D708A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 角色选择页面
class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen>
    with TickerProviderStateMixin {
  String? selectedCharacterId;
  String? _animatingCharacterId;
  final Map<String, AnimationController> _animationControllers = {};

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    super.dispose();
  }

  void _startAnimation(String characterId) {
    // 1. 彻底清理现有的动画控制器，防止内存泄漏和竞争
    for (var controller in _animationControllers.values) {
      try {
        controller.stop();
        controller.dispose();
      } catch (_) {
        // 忽略已释放或正在释放的控制器的异常
      }
    }
    _animationControllers.clear();

    // 2. 创建新的动画控制器
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _animationControllers[characterId] = controller;
    
    // 3. 动画完成后安全清理
    controller.forward().then((_) {
      if (mounted && _animationControllers[characterId] == controller) {
        _animationControllers.remove(characterId);
        try {
          controller.dispose();
        } catch (_) {}
        setState(() {
          if (_animatingCharacterId == characterId) {
            _animatingCharacterId = null;
          }
        });
      }
    }).catchError((_) {
      // 捕获动画过程中可能产生的异常（例如被dispose）
    });

    setState(() {
      _animatingCharacterId = characterId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit(context);
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 关键区域：背景美化
            const Positioned.fill(
              child: CyberBackground(),
            ),
            Column(
              children: [
                // 自定义美化标题栏
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF101722).withValues(alpha: 0.9),
                        const Color(0xFF0A0F16).withValues(alpha: 0.0),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFF6CE4FF).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "// SYSTEM_NEURAL_LINK",
                            style: TextStyle(
                              color: const Color(0xFF6CE4FF).withValues(alpha: 0.5),
                              fontSize: 8,
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                          CyberButton(
                            width: 60,
                            height: 20,
                            label: "返回",
                            fontSize: 9,
                            color: const Color(0xFF6CE4FF),
                            onPressed: () async {
                              final shouldPop = await _confirmExit(context);
                              if (shouldPop && context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.psychology, color: Color(0xFF6CE4FF), size: 20),
                          const SizedBox(width: 15),
                          const Text(
                            '配置接入单元',
                            style: TextStyle(
                              color: Color(0xFFE1E9FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF6CE4FF),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Icon(Icons.psychology, color: Color(0xFF6CE4FF), size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              // 角色选择说明
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Text(
                  '选择渗透载体 · 同步战术算法',
                  style: TextStyle(
                    fontSize: 13, 
                    color: Color(0xFF8FA3C0),
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // 角色列表
              Expanded(
                child: ListView.builder(
                  itemCount: characterDatabase.length,
                  itemBuilder: (context, index) {
                    final character = characterDatabase.values.elementAt(index);
                    final isSelected = selectedCharacterId == character.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCharacterId = character.id;
                        });
                        _startAnimation(character.id);
                      },
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 160),
                        scale: isSelected ? 1.02 : 1.0,
                        child: Container(
                          height: 140,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0F16).withValues(alpha: isSelected ? 0.9 : 0.6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: (isSelected ? const Color(0xFF6CE4FF) : const Color(0xFF1E2C3C))
                                  .withValues(alpha: isSelected ? 0.8 : 0.4),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: const Color(0xFF6CE4FF).withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ] : [],
                          ),
                          child: Stack(
                            children: [
                              // 内部扫描线 (选中时显示)
                              if (isSelected)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: const CyberScanline(color: Color(0x336CE4FF)),
                                  ),
                                ),
                              // 装饰边角
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: CyberCornerPainter(
                                    color: (isSelected ? const Color(0xFF6CE4FF) : const Color(0xFF1E2C3C))
                                        .withValues(alpha: 0.5),
                                    cornerSize: 15,
                                  ),
                                ),
                              ),
                              // 角色内容
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            character.name,
                                            style: const TextStyle(
                                              color: Color(0xFFE1E9FF),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'HP ${character.maxHp}  ·  DECK ${character.startingDeck.length}',
                                            style: const TextStyle(
                                              color: Color(0xFF8FA3C0),
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            character.description,
                                            style: const TextStyle(
                                              color: Color(0xFF5D708A),
                                              fontSize: 11,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_animatingCharacterId == character.id)
                                Builder(
                                  builder: (context) {
                                    final controller = _animationControllers[character.id];
                                    if (controller == null) return const SizedBox.shrink();
                                    return Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: controller,
                                        builder: (context, _) {
                                          return CustomPaint(
                                            painter: _HoloGridPainter(
                                              progress: controller.value,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 关键区域：开始战斗（从第1层随机抽取，不再直接进入地图）
              Container(
                padding: const EdgeInsets.all(16),
                child: CyberButton(
                  heroTag: 'main_action_button',
                  width: double.infinity,
                  label: '同步数据并开始渗透',
                  onPressed: selectedCharacterId != null
                      ? () {
                          GameProgress.startRun();
                          // 保存选择的角色ID到全局状态
                          GameState.selectedCharacterId = selectedCharacterId!;
                          // 更新玩家HP
                          final character = characterDatabase[selectedCharacterId!]!;
                          GameState.playerMaxHp = character.maxHp;
                          GameState.playerHp = character.maxHp;
                          // 初始化持久化牌组
                          GameState.drawPile = List.from(character.startingDeck);
                          Navigator.push(
                            context,
                            createHoloRoute(
                              const MapScreen(
                                canReturnToGame: true,
                                canSelect: true, // 初始选择角色后，允许选择第一个节点
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Future<bool> _confirmExit(BuildContext context) async {
    final res = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "EXIT_CONFIRM",
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
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFF6A6A),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "EXIT_CONFIRMATION",
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
                        '确认要退出角色选择并返回主菜单吗？',
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
                            label: '取消',
                            color: const Color(0xFF6CE4FF),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                          const SizedBox(width: 16),
                          CyberButton(
                            width: 100,
                            height: 36,
                            fontSize: 12,
                            label: '确认',
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
}
