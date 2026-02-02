// game_state.dart
// 作用：提供跨关卡持久的玩家状态（HP/MaxHP），供地图与战斗页面共享

import 'dart:math';
import 'package:flutter/material.dart';
import 'brainchip_data.dart';

class GameState {
  static int playerMaxHp = 80; // 最大完整度 (Max Integrity)
  static int playerHp = 80;    // 当前完整度 (Current Integrity)
  static int playerBlock = 0;  // 临时防火墙强度 (Temporary Firewall Strength)
  static int playerStrength = 0; // 临时算力加成 (Temporary Strength)
  
  // 永久初始属性 (Permanent Initial Attributes)
  static int permanentStrength = 0; // 初始算力 (Initial Strength)
  static int permanentBlock = 0;    // 初始防火墙 (Initial Firewall)
  
  static int playerGold = 0;    // 信用点/金币 (Gold)
  static String selectedCharacterId = "ironclad"; // 默认选择铁甲战士
  
  // 数据包（抽牌堆，跨关卡持久化）
  static List<String> drawPile = [];
  
  // 焰心：热量进度（跨关卡持久化）
  static int heatProgress = 0;
  static String? selectedBrainChipId;

  /// 获取当前全局主题色（基于脑机）
  static Color getThemeColor() {
    if (selectedBrainChipId != null) {
      final chip = brainChipDatabase[selectedBrainChipId] ?? brainChipPool.first;
      return Color(chip.themeColor);
    }
    return const Color(0xFF6CE4FF); // 默认青色
  }

  /// 修复完整度
  static void heal(int amount) {
    playerHp = min(playerMaxHp, playerHp + max(0, amount));
  }

  static void reset() {
    playerBlock = 0;
    playerStrength = 0;
    permanentStrength = 0;
    permanentBlock = 0;
    heatProgress = 0;
    drawPile.clear();
  }
}

// 游戏统计信息
class GameStatistics {
  static int totalDamageDealt = 0;
  static int totalDamageBlocked = 0;
  static int totalCardsUsed = 0;
  static int totalTurns = 0;

  // 重置统计信息
  static void reset() {
    totalDamageDealt = 0;
    totalDamageBlocked = 0;
    totalCardsUsed = 0;
    totalTurns = 0;
  }
}
