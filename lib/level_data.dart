// level_data.dart
// 作用：定义地图关卡数据，每个关卡对应怪物ID列表，并提供关卡进度管理
import 'dart:math';

class LevelInfo {
  final String id;
  final String title;
  final List<String> monsterIds;
  final String type; // battle/rest/shop
  const LevelInfo({
    required this.id,
    required this.title,
    required this.monsterIds,
    this.type = 'battle',
  });
}

/// 分层的关卡列表（用于树状地图布局，至少9层）
const List<List<LevelInfo>> levelLayers = [
  // L0 起点（地图展示用）
  [
    LevelInfo(id: 'L0-A', title: '起点·史莱姆', monsterIds: ['slime']),
    LevelInfo(id: 'L0-B', title: '起点·哥布林', monsterIds: ['goblin']),
    LevelInfo(id: 'L0-C', title: '起点·骷髅', monsterIds: ['skeleton']),
  ],
  // L1 初始战斗层（从这里随机抽取进入战斗）
  [
    LevelInfo(id: 'L1-A', title: '森林·史莱姆+哥布林', monsterIds: ['slime', 'goblin']),
    LevelInfo(id: 'L1-B', title: '沼泽·双史莱姆', monsterIds: ['slime', 'slime']),
    LevelInfo(id: 'L1-C', title: '墓地·骷髅', monsterIds: ['skeleton']),
  ],
  // L2 过渡层
  [
    LevelInfo(id: 'L2-A', title: '营地·哥布林小队', monsterIds: ['goblin', 'goblin']),
    LevelInfo(id: 'L2-B', title: '洞穴·骷髅+史莱姆', monsterIds: ['skeleton', 'slime']),
    LevelInfo(id: 'L2-C', title: '小径·哥布林+史莱姆', monsterIds: ['goblin', 'slime']),
    LevelInfo(id: 'R2-D', title: '休息区', monsterIds: [], type: 'rest'),
    LevelInfo(id: 'S2-E', title: '商店', monsterIds: [], type: 'shop'),
  ],
  // L3 提升难度层
  [
    LevelInfo(id: 'L3-A', title: '山道·骷髅队', monsterIds: ['skeleton', 'skeleton']),
    LevelInfo(id: 'L3-B', title: '峡谷·史莱姆群', monsterIds: ['slime', 'slime', 'slime']),
    LevelInfo(id: 'L3-C', title: '通道·哥布林斥候', monsterIds: ['goblin']),
  ],
  // L4 精英前置层
  [
    LevelInfo(id: 'L4-A', title: '精英·兽人战士', monsterIds: ['orc_warrior']),
    LevelInfo(id: 'L4-B', title: '精英·黑暗法师', monsterIds: ['dark_mage']),
    LevelInfo(id: 'L4-C', title: '护卫·兽人+哥布林', monsterIds: ['orc_warrior', 'goblin']),
    LevelInfo(id: 'S4-D', title: '商店', monsterIds: [], type: 'shop'),
  ],
  // L5 混战层
  [
    LevelInfo(id: 'L5-A', title: '暗影营地·法师+骷髅', monsterIds: ['dark_mage', 'skeleton']),
    LevelInfo(id: 'L5-B', title: '战场·兽人+哥布林', monsterIds: ['orc_warrior', 'goblin']),
    LevelInfo(id: 'L5-C', title: '淤泥·史莱姆+法师', monsterIds: ['slime', 'dark_mage']),
  ],
  // L6 强化精英层
  [
    LevelInfo(id: 'L6-A', title: '混战·法师+兽人', monsterIds: ['dark_mage', 'orc_warrior']),
    LevelInfo(id: 'L6-B', title: '防线·兽人+骷髅', monsterIds: ['orc_warrior', 'skeleton']),
    LevelInfo(id: 'L6-C', title: '突袭·哥布林群', monsterIds: ['goblin', 'goblin', 'goblin']),
  ],
  // L7 终章前置层
  [
    LevelInfo(id: 'L7-A', title: '枢纽·法师+骷髅群', monsterIds: ['dark_mage', 'skeleton', 'skeleton']),
    LevelInfo(id: 'L7-B', title: '巢穴·史莱姆王庭', monsterIds: ['slime', 'slime', 'goblin']),
    LevelInfo(id: 'L7-C', title: '城门·兽人巡逻', monsterIds: ['orc_warrior', 'goblin']),
  ],
  // L8 Boss层
  [
    LevelInfo(id: 'L8-A', title: 'Boss·巨龙', monsterIds: ['dragon']),
    LevelInfo(id: 'L8-B', title: 'Boss前哨·法师护卫', monsterIds: ['dark_mage', 'orc_warrior']),
    LevelInfo(id: 'L8-C', title: 'Boss前哨·兽人护卫', monsterIds: ['orc_warrior', 'orc_warrior']),
  ],
];

/// 关卡进度管理
class GameProgress {
  static int currentLayer = 1; // 从第一战斗层开始
  static String? currentLevelId;
  static int currentIndex = 0;
  static final Set<String> defeatedIds = <String>{};

  static void startRun() {
    currentLayer = 1;
    currentLevelId = null;
    defeatedIds.clear();
  }

  static bool hasLayer(int layer) => layer >= 0 && layer < levelLayers.length;
  static List<LevelInfo> getLayer(int layer) => levelLayers[layer];

  static LevelInfo randomLevel(int layer) {
    final ls = getLayer(layer);
    final idx = Random().nextInt(ls.length);
    return ls[idx];
  }

  static LevelInfo startFirstBattle() {
    final info = randomLevel(1);
    currentLayer = 1;
    currentLevelId = info.id;
    currentIndex = indexOfId(1, info.id);
    return info;
  }

  static void markDefeated(String id) {
    defeatedIds.add(id);
  }

  static bool isDefeated(String id) => defeatedIds.contains(id);

  static LevelInfo? nextRandomLevel() {
    final next = currentLayer + 1;
    if (!hasLayer(next)) return null;
    final info = randomLevel(next);
    currentLayer = next;
    currentLevelId = info.id;
    currentIndex = indexOfId(next, info.id);
    return info;
  }

  static void setCurrentLevel(LevelInfo info) {
    currentLevelId = info.id;
    currentIndex = indexOfId(currentLayer, info.id);
  }

  static int indexOfId(int layer, String id) {
    final ls = getLayer(layer);
    for (int i = 0; i < ls.length; i++) {
      if (ls[i].id == id) return i;
    }
    return 0;
  }

  static List<int> allowedNextIndices() {
    final next = currentLayer + 1;
    if (!hasLayer(next)) return const [];
    final ls = getLayer(next);
    final idxs = <int>[];
    for (int i = 0; i < ls.length; i++) {
      if ((i - currentIndex).abs() <= 1) idxs.add(i);
    }
    return idxs;
  }
}