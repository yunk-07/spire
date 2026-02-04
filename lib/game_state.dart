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

  /// 应用脑机装备时的即时效果（仅触发一次）
  static void applyBrainChipInstantEffects(String chipId) {
    final chip = brainChipDatabase[chipId];
    if (chip == null || chip.effect == null) return;

    final effects = chip.effect!.split(';');
    for (var e in effects) {
      final parts = e.trim().split(' ');
      if (parts.isEmpty) continue;
      
      final command = parts[0];
      if (command == 'permanent_max_hp_mult') {
        if (parts.length > 1) {
          final factor = double.tryParse(parts[1]) ?? 1.0;
          if (factor != 1.0) {
            playerMaxHp = (playerMaxHp * factor).round().clamp(1, 999999);
            playerHp = min(playerHp, playerMaxHp);
          }
        }
      }
      // 如果有其他即时效果（如 heal），也可以在这里添加
      if (command == 'heal') {
        if (parts.length > 1) {
          final amount = int.tryParse(parts[1]) ?? 0;
          heal(amount);
        }
      }
    }
  }

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
    playerMaxHp = 80;
    playerHp = 80;
    playerBlock = 0;
    playerStrength = 0;
    permanentStrength = 0;
    permanentBlock = 0;
    playerGold = 0;
    heatProgress = 0;
    selectedBrainChipId = null;
    drawPile.clear();
  }
}

// 游戏统计信息
class GameStatistics {
  // 本场战斗数据 (Current Battle Data)
  static int battleDamageDealt = 0;
  static int battleDamageBlocked = 0;
  static int battleCardsUsed = 0;
  static int battleTurns = 0;

  // 本局数据 (Current Run Data)
  static int totalDamageDealt = 0;
  static int totalDamageBlocked = 0;
  static int totalCardsUsed = 0;
  static int totalTurns = 0;
  static int totalBattlesWon = 0; // 赢得战斗总数

  // 累计数据 (Cumulative Data - Session persistent)
  static int globalDamageDealt = 0;
  static int globalDamageBlocked = 0;
  static int globalCardsUsed = 0;
  static int globalTurns = 0;
  static int globalBattlesWon = 0;
  static int globalRunsCompleted = 0;

  // 重置本场战斗统计信息
  static void resetBattle() {
    battleDamageDealt = 0;
    battleDamageBlocked = 0;
    battleCardsUsed = 0;
    battleTurns = 0;
  }

  // 重置本局统计信息
  static void reset() {
    resetBattle();
    totalDamageDealt = 0;
    totalDamageBlocked = 0;
    totalCardsUsed = 0;
    totalTurns = 0;
    totalBattlesWon = 0;
  }

  // 结算当前局数据到累计数据
  static void commitRunStats() {
    globalDamageDealt += totalDamageDealt;
    globalDamageBlocked += totalDamageBlocked;
    globalCardsUsed += totalCardsUsed;
    globalTurns += totalTurns;
    globalBattlesWon += totalBattlesWon;
    globalRunsCompleted++;
  }
}
