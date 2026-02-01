import 'dart:math';
import 'package:flutter/material.dart';
import 'brainchip_data.dart';
import 'game_state.dart';
import 'nation_selection_screen.dart';
import 'main.dart';
import 'theme_config.dart';

class BrainChipSelectionScreen extends StatefulWidget {
  const BrainChipSelectionScreen({super.key});
  @override
  State<BrainChipSelectionScreen> createState() => _BrainChipSelectionScreenState();
}

class _BrainChipSelectionScreenState extends State<BrainChipSelectionScreen> {
  // 直接初始化以防止 LateInitializationError
  BrainChip chip = brainChipPool[Random().nextInt(brainChipPool.length)];

  @override
  void initState() {
    super.initState();
    GameState.selectedBrainChipId = chip.id;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(chip.themeColor);

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          // 1. 动态径向背景
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    themeColor.withValues(alpha: 0.12),
                    const Color(0xFF020408),
                  ],
                ),
              ),
            ),
          ),
          
          // 2. 基础赛博背景
          const Positioned.fill(child: CyberBackground()),
          
          // 3. 动态扫描线 (增强科幻感)
          Positioned.fill(child: CyberScanline(color: themeColor.withValues(alpha: 0.15))),
          
          // 4. 顶部标题
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "NEURAL INTERFACE ASSIGNED",
                  style: TextStyle(
                    color: themeColor.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontFamily: 'monospace',
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "系统已分配神经接口组件",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: themeColor, blurRadius: 15),
                      Shadow(color: themeColor, blurRadius: 5),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 80,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, themeColor, Colors.transparent],
                    ),
                    boxShadow: [BoxShadow(color: themeColor, blurRadius: 8)],
                  ),
                ),
              ],
            ),
          ),

          // 5. 核心展示区
          Center(
            child: Hero(
              tag: 'brainchip_card',
              child: _buildChipCard(),
            ),
          ),

          // 6. 底部确认区
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusDot(themeColor),
                      const SizedBox(width: 8),
                      Text(
                        "数据链路连接稳定 // 硬件同步就绪",
                        style: TextStyle(
                          color: themeColor.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 320,
                    child: CyberButton(
                      label: '确认并初始化连接',
                      height: 56,
                      fontSize: 16,
                      color: themeColor,
                      onPressed: () {
                        Navigator.pushReplacement(context, createHoloRoute(const NationSelectionScreen()));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 4)],
      ),
    );
  }

  Widget _buildChipCard() {
    final themeColor = Color(chip.themeColor);

    return Container(
      width: 350,
      height: 500,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: themeColor.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: -5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // 卡片背景
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F16).withValues(alpha: 0.98),
                image: DecorationImage(
                  image: const AssetImage('assets/images/grid_pattern.png'), // 如果有网格纹理
                  repeat: ImageRepeat.repeat,
                  opacity: 0.05,
                  fit: BoxFit.none,
                  onError: (e, s) {},
                ),
              ),
            ),
            
            // 内容布局
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部：等级与套装
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          border: Border.all(color: themeColor.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "LV.${chip.level}",
                          style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(IconData(chip.suiteIconCode, fontFamily: 'MaterialIcons'), color: themeColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            chip.suiteName,
                            style: TextStyle(color: themeColor, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // 名称与编号
                  Text(
                    "INTERFACE_NAME",
                    style: TextStyle(color: themeColor.withValues(alpha: 0.4), fontSize: 10, fontFamily: 'monospace'),
                  ),
                  Text(
                    chip.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 装饰分割线
                  Row(
                    children: [
                      Container(width: 40, height: 4, color: themeColor),
                      const SizedBox(width: 4),
                      Container(width: 10, height: 4, color: themeColor.withValues(alpha: 0.3)),
                      const SizedBox(width: 4),
                      Expanded(child: Container(height: 1, color: themeColor.withValues(alpha: 0.1))),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // 功能描述
                  Text(
                    "FUNCTION_LOG >",
                    style: TextStyle(color: themeColor.withValues(alpha: 0.4), fontSize: 10, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      chip.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 17,
                        height: 1.6,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  // 底部：版本与唯一识别码
                  const SizedBox(height: 20),
                  Divider(color: themeColor.withValues(alpha: 0.1)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "FIRMWARE_REV",
                            style: TextStyle(color: themeColor.withValues(alpha: 0.3), fontSize: 8, fontFamily: 'monospace'),
                          ),
                          Text(
                            "v4.0.2-stable",
                            style: TextStyle(color: themeColor.withValues(alpha: 0.5), fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "UID_REF",
                            style: TextStyle(color: themeColor.withValues(alpha: 0.3), fontSize: 8, fontFamily: 'monospace'),
                          ),
                          Text(
                            chip.id.toUpperCase(),
                            style: TextStyle(color: themeColor.withValues(alpha: 0.5), fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
