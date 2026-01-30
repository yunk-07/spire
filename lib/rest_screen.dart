/// 逻辑修复站页面
/// 提供生命值修复（恢复已受损生命的50%）和时空跳跃（跳跃到当前层级任意位置）功能
library;

import 'package:flutter/material.dart';
import 'dart:math';
import 'start_screen.dart';
import 'game_state.dart';
import 'level_data.dart';
import 'main.dart';
import 'map_screen.dart';

class RestScreen extends StatefulWidget {
  final String levelId;

  const RestScreen({super.key, required this.levelId});

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> with TickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _pulseController;
  late AnimationController _glitchController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  void _onHeal() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // 核心区域备注：逻辑修复逻辑 - 恢复已受损生命的 50%
    final missingHp = GameState.playerMaxHp - GameState.playerHp;
    if (missingHp > 0) {
      final healAmount = (missingHp * 0.5).round();
      GameState.heal(healAmount);
    }
    
    _finishRest();
  }

  void _onTimeJump() async {
    if (_isProcessing) return;
    Navigator.push(
      context,
      createHoloRoute(const MapScreen(canSelect: true, isJumpMode: true)),
    );
  }

  void _finishRest() {
    GameProgress.markDefeated(widget.levelId);
    if (mounted) {
      Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = GameState.getThemeColor();

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
      child: TickerMode(
        enabled: ModalRoute.of(context)?.isCurrent ?? true,
        child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 40),
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _styledHeader(),
                          const SizedBox(height: 12),
                          _metaRow(themeColor),
                          const SizedBox(height: 24),
                          _logicPanel(themeColor, _buildVisualCenter(themeColor)),
                          const SizedBox(height: 24),
                          _logicPanel(themeColor, _buildOptions(themeColor)),
                          const SizedBox(height: 24),
                          _logicPanel(themeColor, _buildStatusFooter(themeColor)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isProcessing) _buildProcessingOverlay(themeColor),
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
                            color: GameState.getThemeColor(),
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
  

  /*
  Widget _buildBackground() {
    return const SizedBox.shrink();
  }

  Widget _buildHeader(Color color) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.02),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 装饰性角标 - 左上
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: 2),
                  left: BorderSide(color: color, width: 2),
                ),
              ),
            ),
          ),
          // 装饰性角标 - 右下
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: 2),
                  right: BorderSide(color: color, width: 2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // 状态指示灯
                Column(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.3)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.3)),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // 标题内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "修复站",
                          style: TextStyle(
                            color: color,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontFamily: 'Courier',
                            shadows: [
                              Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "LOGIC_REPAIR STATION // ${widget.levelId}",
                            style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 9, fontFamily: 'Courier'),
                          ),
                          const SizedBox(width: 12),
                          _buildHeaderBadge("ONLINE", color),
                          const SizedBox(width: 8),
                          _buildHeaderBadge("ENCRYPTED", color.withValues(alpha: 0.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                // 右侧功能图标
                Icon(Icons.qr_code_scanner, color: color, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
  */

  /*
  Widget _buildHeaderBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
      ),
    );
  }
  */

  Widget _buildVisualCenter(Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2 * _pulseController.value),
                    blurRadius: 30 + 20 * _pulseController.value,
                    spreadRadius: 5 + 10 * _pulseController.value,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _CenterCorePainter(
                  color: color,
                  pulse: _pulseController.value,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "CORE_STABILITY: ${(85 + _random.nextInt(15))}%",
              style: TextStyle(color: color, fontSize: 12, fontFamily: 'Courier', letterSpacing: 2),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptions(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildCyberOption(
            title: "逻辑回溯",
            subtitle: "RECONSTRUCT_INTEGRITY",
            desc: "恢复 50% 已受损的生命完整度",
            icon: Icons.history_edu,
            color: color,
            onTap: _onHeal,
          ),
          const SizedBox(height: 20),
          _buildCyberOption(
            title: "时空跳跃",
            subtitle: "DIMENSIONAL_SHIFT",
            desc: "重新锚定位置，跳跃到当前层级任意节点",
            icon: Icons.auto_fix_high,
            color: const Color(0xFFAD00FF),
            onTap: _onTimeJump,
          ),
        ],
      ),
    );
  }

  Widget _buildCyberOption({
    required String title,
    required String subtitle,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: color),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                      Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 10, fontFamily: 'Courier')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Courier')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFooter(Color color) {
    final hpPercent = GameState.playerHp / GameState.playerMaxHp;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("SYSTEM_INTEGRITY", style: TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Courier')),
              Text("${GameState.playerHp} / ${GameState.playerMaxHp}", 
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: hpPercent,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay(Color color) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 40),
            _GlitchText(
              text: "正在执行重组协议...",
              style: TextStyle(color: color, fontSize: 18, fontFamily: 'Courier', letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _styledHeader() {
  final color = GameState.getThemeColor();
  return Column(
    children: [
      Text('修复站', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8, fontFamily: 'monospace', shadows: [Shadow(color: color, blurRadius: 20)])),
      const SizedBox(height: 12),
      Text('LOGIC REPAIR v3.4', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.4), letterSpacing: 2, fontFamily: 'monospace')),
    ],
  );
}

Widget _metaRow(Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10)]), child: Row(children: [Icon(Icons.qr_code_scanner, size: 14, color: color), const SizedBox(width: 6), const Text("OPTIONS: 2", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))])),
        const SizedBox(width: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4))), child: Row(children: [Icon(Icons.memory, size: 14, color: color), const SizedBox(width: 6), const Text("NODE", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1))])),
      ],
    ),
  );
}

Widget _logicPanel(Color color, Widget child) {
  return Container(
    width: 720,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    decoration: BoxDecoration(color: const Color(0xFF0A0F16).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 2), const BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))]),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Stack(
        children: [
          Positioned.fill(child: CyberScanline(color: color.withValues(alpha: 0.08))),
          Positioned.fill(child: CustomPaint(painter: CyberCornerPainter(color: color.withValues(alpha: 0.5)))),
          Column(mainAxisSize: MainAxisSize.min, children: [Row(children: [Icon(Icons.qr_code_scanner, size: 16, color: color), const SizedBox(width: 8), Text("// REPAIR_CHANNEL", style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'monospace', letterSpacing: 2)), const Spacer(), Text("SESSION", style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))]), const SizedBox(height: 12), Container(width: double.infinity, height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.2), Colors.transparent]))), const SizedBox(height: 16), child]),
        ],
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final themeColor = GameState.getThemeColor();
    final paint = Paint()..color = themeColor.withValues(alpha: 0.05)..strokeWidth = 1;
    const spacing = 30.0;
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

/*
class _CyberBackgroundPainter extends CustomPainter {
  final double glitchValue;
  final Random random;
  _CyberBackgroundPainter({required this.glitchValue, required this.random});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    // 绘制网格
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // 随机故障线条
    if (random.nextDouble() > 0.8) {
      final glitchPaint = Paint()
        ..color = const Color(0xFF00F0FF).withValues(alpha: 0.1)
        ..strokeWidth = 2;
      final y = random.nextDouble() * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), glitchPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
*/

class _CenterCorePainter extends CustomPainter {
  final Color color;
  final double pulse;
  _CenterCorePainter({required this.color, required this.pulse});

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
    canvas.rotate(pulse * 2 * pi);
    
    final tickPaint = Paint()
      ..color = color
      ..strokeWidth = 3;

    for (int i = 0; i < 8; i++) {
      canvas.rotate(pi / 4);
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

class _GlitchText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _GlitchText({required this.text, required this.style});

  @override
  State<_GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<_GlitchText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

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
