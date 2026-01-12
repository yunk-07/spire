// level_data.dart
// 作用：定义地图关卡数据，每个关卡对应怪物ID列表，并提供关卡进度管理
import 'dart:math';

class LevelInfo {
  final String id;
  final String title;
  final List<String> programIds;
  final String type; // infiltration/sync/exchange
  const LevelInfo({
    required this.id,
    required this.title,
    required this.programIds,
    this.type = 'infiltration',
  });
}

/// 分层的关卡列表（用于树状地图布局，至少9层）
const List<List<LevelInfo>> levelLayers = [
  // L0 起点（地图展示用）
  [
    LevelInfo(id: 'L0-A', title: '初始接入点·爬虫程序', programIds: ['slime']),
    LevelInfo(id: 'L0-B', title: '初始接入点·逻辑碎片', programIds: ['goblin']),
    LevelInfo(id: 'L0-C', title: '初始接入点·僵尸进程', programIds: ['skeleton']),
  ],
  // L1 初始战斗层（从这里随机抽取进入战斗）
  [
    LevelInfo(id: 'L1-A', title: '数据丛林·基础防御', programIds: ['slime', 'goblin']),
    LevelInfo(id: 'L1-B', title: '内存溢出区·冗余数据', programIds: ['slime', 'slime']),
    LevelInfo(id: 'L1-C', title: '进程坟场·死循环', programIds: ['skeleton']),
  ],
  // L2 过渡层
  [
    LevelInfo(id: 'L2-A', title: '集群节点·逻辑块', programIds: ['goblin', 'goblin']),
    LevelInfo(id: 'L2-B', title: '逻辑空洞·碎片数据', programIds: ['skeleton', 'slime']),
    LevelInfo(id: 'L2-C', title: '虚拟通道·拦截器', programIds: ['goblin', 'slime']),
    LevelInfo(id: 'R2-D', title: '数据缓存站', programIds: [], type: 'sync'),
    LevelInfo(id: 'S2-E', title: '数据交易所', programIds: [], type: 'exchange'),
  ],
  // L3 提升难度层
  [
    LevelInfo(id: 'L3-A', title: '上行链路·加密锁', programIds: ['skeleton', 'skeleton']),
    LevelInfo(id: 'L3-B', title: '协议裂痕·异常流', programIds: ['slime', 'slime', 'slime']),
    LevelInfo(id: 'L3-C', title: '传输网关·探测器', programIds: ['goblin']),
  ],
  // L4 精英前置层
  [
    LevelInfo(id: 'L4-A', title: '高级防御程序·ORC', programIds: ['orc_warrior']),
    LevelInfo(id: 'L4-B', title: '高级加密模块·MAGE', programIds: ['dark_mage']),
    LevelInfo(id: 'L4-C', title: '守护进程·复合防御', programIds: ['orc_warrior', 'goblin']),
    LevelInfo(id: 'S4-D', title: '数据交易所', programIds: [], type: 'exchange'),
  ],
  // L5 混战层
  [
    LevelInfo(id: 'L5-A', title: '加密集群·深度扫描', programIds: ['dark_mage', 'skeleton']),
    LevelInfo(id: 'L5-B', title: '冲突域·并行处理', programIds: ['orc_warrior', 'goblin']),
    LevelInfo(id: 'L5-C', title: '溢出协议·混合异常', programIds: ['slime', 'dark_mage']),
  ],
  // L6 强化精英层
  [
    LevelInfo(id: 'L6-A', title: '全域冲突·强化防御', programIds: ['dark_mage', 'orc_warrior']),
    LevelInfo(id: 'L6-B', title: '系统防火墙·前哨', programIds: ['orc_warrior', 'skeleton']),
    LevelInfo(id: 'L6-C', title: '高频突袭·探测群', programIds: ['goblin', 'goblin', 'goblin']),
  ],
  // L7 终章前置层
  [
    LevelInfo(id: 'L7-A', title: '逻辑枢纽·全量防御', programIds: ['dark_mage', 'skeleton', 'skeleton']),
    LevelInfo(id: 'L7-B', title: '系统内核·深度扫描', programIds: ['slime', 'slime', 'goblin']),
    LevelInfo(id: 'L7-C', title: '系统防火墙·主网关', programIds: ['orc_warrior', 'goblin']),
  ],
  // L8 Boss层
  [
    LevelInfo(id: 'L8-A', title: '核心防火墙·DRAGON', programIds: ['dragon']),
    LevelInfo(id: 'L8-B', title: '核心防御·高级模块', programIds: ['dark_mage', 'orc_warrior']),
    LevelInfo(id: 'L8-C', title: '核心防御·物理隔离', programIds: ['orc_warrior', 'orc_warrior']),
  ],
];

/// 关卡进度管理
class GameProgress {
  static int currentLayer = 1; // 从第一战斗层开始
  static String? currentLevelId;
  static int currentIndex = 0;
  static final Set<String> defeatedIds = <String>{};

  static void startRun() {
    currentLayer = 0;
    currentLevelId = null;
    defeatedIds.clear();
  }

  static LevelInfo startFirstBattle() {
    final info = randomLevel(1); // 从第一战斗层随机开始
    setCurrentLevel(info);
    return info;
  }

  static bool hasLayer(int layer) => layer >= 0 && layer < levelLayers.length;
  static List<LevelInfo> getLayer(int layer) => levelLayers[layer];

  static LevelInfo randomLevel(int layer) {
    final ls = getLayer(layer);
    final idx = Random().nextInt(ls.length);
    return ls[idx];
  }

  static LevelInfo? nextRandomLevel() {
    if (currentLayer + 1 >= levelLayers.length) return null;
    return randomLevel(currentLayer + 1);
  }

  static void setCurrentLevel(LevelInfo level) {
    currentLevelId = level.id;
    // 找到该level所在的层
    for (int i = 0; i < levelLayers.length; i++) {
      if (levelLayers[i].any((l) => l.id == level.id)) {
        currentLayer = i;
        currentIndex = levelLayers[i].indexWhere((l) => l.id == level.id);
        break;
      }
    }
  }

  static void markDefeated(String id) {
    defeatedIds.add(id);
  }

  static bool isDefeated(String id) {
    return defeatedIds.contains(id);
  }

  static List<int> allowedNextIndices() {
    // 简化逻辑：下一层的所有节点都可选
    if (currentLayer + 1 >= levelLayers.length) return [];
    return List.generate(levelLayers[currentLayer + 1].length, (i) => i);
  }
}
