// campfire_screen.dart
// 作用：篝火处页面，提供“休息”与“锻造”（移除一张牌）两种选择
import 'package:flutter/material.dart';
import 'dart:math';
import 'start_screen.dart';
import 'game_state.dart';
import 'card_data.dart';
import 'main.dart';
import 'map_screen.dart';
import 'level_data.dart';

class CampfireScreen extends StatefulWidget {
  final String levelId;
  const CampfireScreen({super.key, required this.levelId});
  @override
  State<CampfireScreen> createState() => _CampfireScreenState();
}

class _CampfireScreenState extends State<CampfireScreen> with TickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = GameState.getThemeColor();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit(context);
        if (shouldExit && context.mounted) {
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _styledHeader(),
                    const SizedBox(height: 12),
                    _metaRow(color),
                    const SizedBox(height: 24),
                    _logicPanel(color, _buildVisualCenter()),
                    const SizedBox(height: 24),
                    _logicPanel(color, _options(color)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            if (_isProcessing) _processingOverlay(color),
          ],
        ),
      ),
      ),
    );
  }

  // Widget _buildHeader(Color color) {
  //   return Container(
  //     margin: const EdgeInsets.all(16),
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: color.withValues(alpha: 0.05),
  //       border: Border.all(color: color.withValues(alpha: 0.2)),
  //       borderRadius: BorderRadius.circular(4),
  //       boxShadow: [
  //         BoxShadow(color: color.withValues(alpha: 0.02), blurRadius: 10, spreadRadius: 2),
  //       ],
  //     ),
  //     child: Stack(
  //       children: [
  //         Positioned.fill(child: CyberScanline(color: color.withValues(alpha: 0.06))),
  //         Positioned.fill(child: CustomPaint(painter: CyberCornerPainter(color: color.withValues(alpha: 0.3)))),
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: Row(
  //             children: [
  //               Column(
  //                 children: [
  //                   Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
  //                   const SizedBox(height: 4),
  //                   Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.3))),
  //                   const SizedBox(height: 4),
  //                   Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.3))),
  //                 ],
  //               ),
  //               const SizedBox(width: 16),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     FittedBox(
  //                       fit: BoxFit.scaleDown,
  //                       alignment: Alignment.centerLeft,
  //                       child: Text(
  //                         "篝火处",
  //                         style: TextStyle(
  //                           color: color,
  //                           fontSize: 22,
  //                           fontWeight: FontWeight.bold,
  //                           letterSpacing: 2,
  //                           fontFamily: 'monospace',
  //                           shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 4),
  //                     Row(
  //                       children: [
  //                         Text("CAMPFIRE NODE // ${widget.levelId}", style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 9, fontFamily: 'monospace')),
  //                         const SizedBox(width: 12),
  //                         _headerBadge("ONLINE", color),
  //                         const SizedBox(width: 8),
  //                         _headerBadge("ENCRYPTED", color.withValues(alpha: 0.5)),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               Icon(Icons.local_fire_department, color: color, size: 24),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // Widget _headerBadge(String label, Color color) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
  //     decoration: BoxDecoration(
  //       color: color.withValues(alpha: 0.15),
  //       border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
  //       borderRadius: BorderRadius.circular(2),
  //     ),
  //     child: Text(label, style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
  //   );
  // }

  Widget _buildVisualCenter() {
    final flameColor = const Color(0xFFFF6A00);
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
                    color: flameColor.withValues(alpha: 0.15 * (1 + _pulseController.value)),
                    blurRadius: 30 + 20 * _pulseController.value,
                    spreadRadius: 5 + 10 * _pulseController.value,
                  ),
                ],
              ),
              child: CustomPaint(painter: _CampfireCorePainter(color: flameColor, pulse: _pulseController.value)),
            ),
            const SizedBox(height: 20),
            Text(
              "HEAT_LEVEL: ${GameState.heatProgress}",
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace', letterSpacing: 2),
            ),
          ],
        );
      },
    );
  }

  Widget _options(Color color) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F16).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 2),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            children: [
              Positioned.fill(child: CyberScanline(color: color.withValues(alpha: 0.08))),
              Positioned.fill(child: CustomPaint(painter: CyberCornerPainter(color: color.withValues(alpha: 0.5)))),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _optionCard(
                    title: "休息",
                    subtitle: "REGENERATE",
                    desc: "恢复缺失生命的 50%",
                    color: GameState.getThemeColor(),
                    icon: Icons.hotel,
                    onTap: _rest,
                  ),
                  const SizedBox(height: 16),
                  _optionCard(
                    title: "锻造",
                    subtitle: "PURGE_CARD",
                    desc: "移除一张牌，优化指令集",
                    color: const Color(0xFFFFD700),
                    icon: Icons.build,
                    onTap: _forgeRemove,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard({
    required String title,
    required String subtitle,
    required String desc,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: color),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F16),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _energyBadge(int cost, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F16),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flash_on, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            "$cost",
            style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _rarityColor(int level) {
    switch (level) {
      case 1:
        return GameState.getThemeColor();
      case 2:
        return const Color(0xFFFFA726);
      case 3:
        return const Color(0xFFAB47BC);
      case 4:
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFFFF6A6A);
    }
  }

  Color _suiteColor(CardSuite suite) {
    switch (suite) {
      case CardSuite.classic: return GameState.getThemeColor();
      case CardSuite.overload: return const Color(0xFFFF4444);
      case CardSuite.secure: return const Color(0xFFC3A6FF);
      case CardSuite.industrial: return const Color(0xFFFFB344);
      case CardSuite.quantum: return const Color(0xFFE26CFF);
      case CardSuite.demon: return const Color(0xFF9D00FF);
      case CardSuite.holy: return const Color(0xFFFFD700);
    }
  }

  void _rest() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final missingHp = GameState.playerMaxHp - GameState.playerHp;
    if (missingHp > 0) {
      final healAmount = (missingHp * 0.5).round();
      GameState.heal(healAmount);
    }
    _finish();
  }

  void _forgeRemove() async {
    if (_isProcessing) return;
    final ids = List<String>.from(GameState.drawPile);
    if (ids.isEmpty) {
      CyberToast.show(context, "当前牌堆为空，无法锻造移除");
      return;
    }
    final removed = await _showRemoveDialog(context, ids);
    if (removed != null) {
      GameState.drawPile.remove(removed);
      _finish();
    }
  }

  Future<String?> _showRemoveDialog(BuildContext context, List<String> ids) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final accent = const Color(0xFFFFD700);
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F16).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 24, spreadRadius: 2)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '选择一张牌进行移除',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      itemCount: ids.length,
                      itemBuilder: (_, i) {
                        final id = ids[i];
                        final data = cardDatabase[id];
                        final name = data?.name ?? id;
                        final desc = data?.description ?? '';
                        final lv = data?.level ?? 0;
                        final cost = data?.cost ?? 0;
                        final suite = data?.suite ?? CardSuite.classic;
                        final suiteColor = _suiteColor(suite);
                        final rarityColor = _rarityColor(lv);
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: suiteColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: suiteColor.withValues(alpha: 0.7), width: 1.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: suiteColor, fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        if (desc.isNotEmpty)
                                          Text(
                                            desc,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  CyberButton(
                                    width: 80,
                                    height: 32,
                                    fontSize: 12,
                                    label: '移除',
                                    color: suiteColor,
                                    onPressed: () => Navigator.pop(ctx, id),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _miniBadge("Lv$lv", rarityColor),
                                  const SizedBox(width: 8),
                                  _energyBadge(cost, suiteColor.withValues(alpha: 0.9)),
                                ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  CyberButton(
                    width: 120,
                    height: 36,
                    fontSize: 12,
                    label: '取消',
                    color: GameState.getThemeColor(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _finish() {
    GameProgress.markDefeated(widget.levelId);
    Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
  }

  Widget _processingOverlay(Color color) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: GameState.getThemeColor()),
      ),
    );
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
            constraints: const BoxConstraints(maxWidth: 320),
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F16).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFF6A6A).withValues(alpha: 0.8), width: 2),
                boxShadow: [BoxShadow(color: const Color(0xFFFF6A6A).withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 2)],
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
                    child: CustomPaint(painter: CyberCornerPainter(color: const Color(0x66FF6A6A))),
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
                        style: TextStyle(color: Color(0xFFE1E9FF), fontSize: 14, height: 1.6, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CyberButton(width: 100, height: 36, fontSize: 12, label: '维持接入', color: GameState.getThemeColor(), onPressed: () => Navigator.pop(ctx, false)),
                          const SizedBox(width: 16),
                          CyberButton(width: 100, height: 36, fontSize: 12, label: '确认断开', color: const Color(0xFFFF6A6A), onPressed: () => Navigator.pop(ctx, true)),
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

Widget _styledHeader() {
  final color = GameState.getThemeColor();
  return Column(
    children: [
      Text('篝火处', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8, fontFamily: 'monospace', shadows: [Shadow(color: color, blurRadius: 20)])),
      const SizedBox(height: 12),
      Text('CAMPFIRE v3.4', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.4), letterSpacing: 2, fontFamily: 'monospace')),
    ],
  );
}

Widget _metaRow(Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10)]), child: Row(children: [Icon(Icons.local_fire_department, size: 14, color: color), const SizedBox(width: 6), const Text("OPTIONS: 2", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))])),
        const SizedBox(width: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF0A0F16), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4))), child: Row(children: [Icon(Icons.memory, size: 14, color: color), const SizedBox(width: 6), const Text("NODE", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1))])),
      ],
    ),
  );
}

Widget _logicPanel(Color color, Widget child) {
  return Container(
    constraints: const BoxConstraints(maxWidth: 720),
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    decoration: BoxDecoration(color: const Color(0xFF0A0F16).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 2), const BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))]),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Stack(
        children: [
          Positioned.fill(child: CyberScanline(color: color.withValues(alpha: 0.08))),
          Positioned.fill(child: CustomPaint(painter: CyberCornerPainter(color: color.withValues(alpha: 0.5)))),
          Column(mainAxisSize: MainAxisSize.min, children: [Row(children: [Icon(Icons.local_fire_department, size: 16, color: color), const SizedBox(width: 8), Text("// CAMPFIRE_CHANNEL", style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'monospace', letterSpacing: 2)), const Spacer(), Text("SESSION", style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))]), const SizedBox(height: 12), Container(width: double.infinity, height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.2), Colors.transparent]))), const SizedBox(height: 16), child]),
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

class _CampfireCorePainter extends CustomPainter {
  final Color color;
  final double pulse;
  _CampfireCorePainter({required this.color, required this.pulse});

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
    canvas.rotate(pulse * 2 * pi);
    final tickPaint = Paint()..color = color..strokeWidth = 3;
    for (int i = 0; i < 6; i++) {
      canvas.rotate(pi / 3);
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
