// game_state.dart
// 作用：提供跨关卡持久的玩家状态（HP/MaxHP），供地图与战斗页面共享

import 'dart:math';

class GameState {
  static int playerMaxHp = 80;
  static int playerHp = 80;
  static String selectedCharacterId = "ironclad"; // 默认选择铁甲战士

  static void heal(int amount) {
    playerHp = min(playerMaxHp, playerHp + max(0, amount));
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