// campfire_screen.dart
// 作用：篝火处页面，提供“休息”与“锻造”（移除一张牌）两种选择
import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'game_state.dart';
import 'card_data.dart';
import 'main.dart';
import 'map_screen.dart';
import 'level_data.dart';

class CampfireScreen extends StatefulWidget {
  final LevelInfo? level;
  const CampfireScreen({super.key, this.level});
  @override
  State<CampfireScreen> createState() => _CampfireScreenState();
}

class _CampfireScreenState extends State<CampfireScreen> with TickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _pulseController;

  LevelInfo? get node => widget.level;
  String get levelId => node?.id ?? 'UNKNOWN';
  String get levelTitle => node?.title ?? '篝火处';

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
        final shouldExit = await showCyberConfirmExit(context);
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
            const Positioned.fill(
              child: CyberBackground(),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _styledHeader(),
                          const SizedBox(height: 12),
                          _metaRow(color),
                          const SizedBox(height: 24),
                          CyberLogicPanel(
                            color: color,
                            icon: Icons.local_fire_department,
                            label: "// 核心模块",
                            child: _buildVisualCenter(),
                          ),
                          const SizedBox(height: 24),
                          CyberLogicPanel(
                            color: color,
                            icon: Icons.build,
                            label: "// 交互选项",
                            child: _options(color),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
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
              child: CustomPaint(painter: CyberCampfireCorePainter(color: flameColor, pulse: _pulseController.value)),
            ),
            const SizedBox(height: 20),
            Text(
              "热量等级: ${GameState.heatProgress}",
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
        decoration: ThemeConfig.buildCyberDecoration(color),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CyberScanline(color: color.withValues(alpha: 0.08))),
              Positioned.fill(child: CustomPaint(painter: CyberCornerPainter(color: color.withValues(alpha: 0.5)))),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _optionCard(
                    title: "休息",
                    subtitle: "核心重构",
                    desc: "恢复缺失生命的 50%",
                    color: GameState.getThemeColor(),
                    icon: Icons.hotel,
                    onTap: _rest,
                  ),
                  const SizedBox(height: 16),
                  _optionCard(
                    title: "强化",
                    subtitle: "算力增强",
                    desc: "永久增加 1 点算力",
                    color: const Color(0xFF6CFF9E),
                    icon: Icons.trending_up,
                    onTap: _onUpgradeStrength,
                  ),
                  const SizedBox(height: 16),
                  _optionCard(
                    title: "锻造",
                    subtitle: "指令优化",
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
        decoration: ThemeConfig.buildCyberDecoration(color),
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

  void _onUpgradeStrength() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    GameState.permanentStrength += 1;
    _finish();
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
    GameProgress.markDefeated(levelId);
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

  Widget _styledHeader() {
    final color = GameState.getThemeColor();
    return Column(
      children: [
        Text(levelTitle, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8, fontFamily: 'monospace', shadows: [Shadow(color: color, blurRadius: 20)])),
        const SizedBox(height: 12),
        Text('核心终端 v3.4', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.4), letterSpacing: 2, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _metaRow(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: ThemeConfig.buildCyberDecoration(color), child: Row(children: [Icon(Icons.local_fire_department, size: 14, color: color), const SizedBox(width: 6), const Text("可用操作: 3", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))])),
          const SizedBox(width: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: ThemeConfig.buildCyberDecoration(color, isRight: true), child: Row(children: [Icon(Icons.memory, size: 14, color: color), const SizedBox(width: 6), Text("节点编号: $levelId", style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1))])),
        ],
      ),
    );
  }
}

// 移除底部的旧函数定义



