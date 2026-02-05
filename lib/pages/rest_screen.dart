/// 逻辑修复站页面
/// 提供生命值修复（恢复已受损生命的50%）和时空跳跃（跳跃到当前层级任意位置）功能
library;

import 'package:flutter/material.dart';
import 'dart:math';
import '../config/theme_config.dart';
import '../models/game_state.dart';
import '../models/level_data.dart';
import '../main.dart';
import 'map_screen.dart';

class RestScreen extends StatefulWidget {
  final LevelInfo? level;

  const RestScreen({super.key, this.level});

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> with TickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _pulseController;
  late AnimationController _glitchController;
  final Random _random = Random();

  LevelInfo? get node => widget.level;
  String get levelId => node?.id ?? 'UNKNOWN';
  String get levelTitle => node?.title ?? '修复站';

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

  void _onUpgradeBlock() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    GameState.permanentBlock += 2;
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
    GameProgress.markDefeated(levelId);
    if (mounted) {
      Navigator.pushReplacement(context, createHoloRoute(const MapScreen(canSelect: true)));
    }
  }

  Widget _styledHeader() {
    final color = GameState.getThemeColor();
    return Column(
      children: [
        Text(levelTitle, 
          style: TextStyle(
            fontSize: 32, 
            fontWeight: FontWeight.bold, 
            color: Colors.white, 
            letterSpacing: 8, 
            fontFamily: 'monospace', 
            shadows: [Shadow(color: color, blurRadius: 20)]
          )
        ),
        const SizedBox(height: 12),
        Text('逻辑修复终端 v3.4', 
          style: TextStyle(
            fontSize: 10, 
            color: color.withValues(alpha: 0.4), 
            letterSpacing: 2, 
            fontFamily: 'monospace'
          )
        ),
      ],
    );
  }

  Widget _metaRow(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
            decoration: ThemeConfig.buildCyberDecoration(color), 
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner, size: 14, color: color), 
                const SizedBox(width: 6), 
                const Text("可用操作: 3", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))
              ]
            )
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
            decoration: ThemeConfig.buildCyberDecoration(color, isRight: true), 
            child: Row(
              children: [
                Icon(Icons.memory, size: 14, color: color), 
                const SizedBox(width: 6), 
                Text("节点编号: $levelId", style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1))
              ]
            )
          ),
        ],
      ),
    );
  }

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
                painter: CyberCenterCorePainter(
                  color: color,
                  pulse: _pulseController.value,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "核心稳定性: ${(85 + _random.nextInt(15))}%",
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
            subtitle: "完整性重构",
            desc: "恢复 50% 已受损的生命",
            icon: Icons.history_edu,
            color: color,
            onTap: _onHeal,
          ),
          const SizedBox(height: 20),
          _buildCyberOption(
            title: "防火墙强化",
            subtitle: "防御矩阵强化",
            desc: "永久增加 2 点基础防火墙强度",
            icon: Icons.shield_outlined,
            color: const Color(0xFF6CFF9E),
            onTap: _onUpgradeBlock,
          ),
          const SizedBox(height: 20),
          _buildCyberOption(
            title: "时空跳跃",
            subtitle: "维度偏移",
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
        decoration: ThemeConfig.buildCyberDecoration(color),
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
            CyberGlitchText(
              text: "正在执行重组协议...",
              style: TextStyle(color: color, fontSize: 18, fontFamily: 'Courier', letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = GameState.getThemeColor();

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
                            CyberLogicPanel(
                              color: themeColor,
                              icon: Icons.qr_code_scanner,
                              label: "// 核心状态",
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: ThemeConfig.buildCyberDecoration(themeColor),
                                child: _buildVisualCenter(themeColor),
                              ),
                            ),
                            const SizedBox(height: 24),
                            CyberLogicPanel(
                              color: themeColor,
                              icon: Icons.settings,
                              label: "// 修复协议",
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: ThemeConfig.buildCyberDecoration(themeColor),
                                child: _buildOptions(themeColor),
                              ),
                            ),
                            const SizedBox(height: 24),
                            CyberLogicPanel(
                              color: themeColor,
                              icon: Icons.info_outline,
                              label: "// 系统信息",
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: ThemeConfig.buildCyberDecoration(themeColor),
                                child: _buildStatusFooter(themeColor),
                              ),
                            ),
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
}
