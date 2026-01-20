// level_data.dart
// 作用：定义地图关卡数据，支持动态生成的国度、不规则形状、以及节点间的走线连接
import 'dart:math';
import 'package:flutter/painting.dart';
import 'program_data.dart';

enum LevelType {
  infiltration, // 打怪/渗透
  elite,        // 精英程序（更难的战斗）
  cache,        // 数据缓存站（补给/奖励）
  exchange,     // 数据交易所（商店）
  mystery,      // 未知扰动（随机事件）
  rest,         // 逻辑修复站（回复/强化）
  boss,         // 最终核心
}

class LevelInfo {
  final String id;
  final String title;
  final List<String> programIds;
  final LevelType type;
  final int difficulty; // 1-5
  final List<int> nextLevelIndices; // 连接到下一层节点的索引

  const LevelInfo({
    required this.id,
    required this.title,
    required this.programIds,
    this.type = LevelType.infiltration,
    this.difficulty = 1,
    this.nextLevelIndices = const [],
  });
}

/// 国度模板，用于生成不同风格的国度
class NationTemplate {
  final String namePrefix;
  final String descriptionBase;
  final List<String> possibleMonsters;
  final Color themeColor;

  const NationTemplate({
    required this.namePrefix,
    required this.descriptionBase,
    required this.possibleMonsters,
    required this.themeColor,
  });
}

const List<NationTemplate> nationTemplates = [
  NationTemplate(
    namePrefix: '霓虹',
    descriptionBase: '尖塔高处的霓虹塔段，旧网路核心在此汇聚，不稳定的逻辑碎片游离其间。',
    possibleMonsters: ['slime', 'goblin', 'echo_bug', 'spark_ball', 'byte_imp', 'pulse_rider', 'sentinel', 'arc_knight'],
    themeColor: Color(0xFF6CE4FF),
  ),
  NationTemplate(
    namePrefix: '荒原',
    descriptionBase: '尖塔下的荒原带，荒废的数据垃圾场中隐藏被遗忘的重型协议。',
    possibleMonsters: ['skeleton', 'orc_warrior', 'iron_dummy', 'scythe_hand', 'crawler', 'sentinel', 'arc_knight'],
    themeColor: Color(0xFFFFA726),
  ),
  NationTemplate(
    namePrefix: '深渊',
    descriptionBase: '尖塔阴影下的深渊域，不确定性极高的深层网络，逻辑在此发生扭曲。',
    possibleMonsters: ['dark_mage', 'dragon', 'shadow_hunter', 'grand_manager', 'storm_core', 'arc_knight'],
    themeColor: Color(0xFFAB47BC),
  ),
];

/// 国度数据结构
class Nation {
  final String id;
  final String title;
  final String description;
  final int difficulty; // 难度系数：1-5
  final List<Offset> shapeVertices; // 不规则图形顶点（归一化坐标 0.0-1.0）
  final List<List<LevelInfo>> layers;
  final Color themeColor;

  const Nation({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.shapeVertices,
    required this.layers,
    required this.themeColor,
  });

  /// 获取国度面积系数（难度越高面积越小）
  double get areaScale => (6 - difficulty) / 5.0;
}

/// 关卡进度管理
class GameProgress {
  static int currentLayer = -1;
  static String? currentLevelId;
  static int currentIndex = -1;
  static final Set<String> defeatedIds = <String>{};
  static String? currentNationId;
  static final Set<String> completedNationIds = <String>{};
  
  // 动态生成的国度列表
  static List<Nation> generatedNations = [];

  static Nation get currentNation {
    return generatedNations.firstWhere(
      (n) => n.id == currentNationId,
      orElse: () => generatedNations.isNotEmpty ? generatedNations.first : _dummyNation(),
    );
  }

  static Nation _dummyNation() => Nation(
    id: 'dummy',
    title: '未知区域',
    description: '尚未初始化的扇区',
    difficulty: 1,
    shapeVertices: [Offset(0,0), Offset(1,0), Offset(1,1)],
    layers: [],
    themeColor: const Color(0xFF6CE4FF),
  );

  static List<List<LevelInfo>> get levelLayers => currentNation.layers;

  /// 初始化一局游戏，生成 5-7 个随机国度
  static void startRun() {
    currentLayer = -1;
    currentLevelId = null;
    currentIndex = -1;
    defeatedIds.clear();
    currentNationId = null;
    completedNationIds.clear();
    
    final random = Random();
    final count = 5 + random.nextInt(3); // 5-7个
    generatedNations = List.generate(count, (i) => _generateRandomNation(i));
  }

  static Nation _generateRandomNation(int index) {
    final random = Random();
    final template = nationTemplates[random.nextInt(nationTemplates.length)];
    final difficulty = 1 + random.nextInt(5);
    
    // 生成不规则顶点
    final vertexCount = 3 + random.nextInt(4); // 3-6个顶点
    final vertices = List.generate(vertexCount, (i) {
      final angle = (i / vertexCount) * 2 * pi;
      final dist = 0.3 + random.nextDouble() * 0.2;
      return Offset(0.5 + cos(angle) * dist, 0.5 + sin(angle) * dist);
    });

    // 生成层级和节点 - 地图变得更大，层数增加到 8-12 层
    final layerCount = 8 + random.nextInt(5); 
    final List<List<LevelInfo>> layers = [];
    
    for (int l = 0; l < layerCount; l++) {
      final isLastLayer = l == layerCount - 1;
      final isFirstLayer = l == 0;
      
      // 节点数量增加，中间层节点更多 (3-5个)，首尾较少
      int nodeCount;
      if (isLastLayer) {
        nodeCount = 1;
      } else if (isFirstLayer) {
        nodeCount = 2 + random.nextInt(2); // 起始 2-3 个入口
      } else {
        nodeCount = 3 + random.nextInt(3); // 中间 3-5 个节点
      }
      
      final layerNodes = List.generate(nodeCount, (n) {
        final id = 'N${index}_L${l}_N$n';
        LevelType type = LevelType.infiltration;
        
        if (isLastLayer) {
          type = LevelType.boss;
        } else if (isFirstLayer) {
          type = LevelType.infiltration; // 入口总是战斗
        } else {
          // 随机节点类型，更多样化
          double roll = random.nextDouble();
          if (roll < 0.5) {
            type = LevelType.infiltration;
          } else if (roll < 0.65) {
            type = LevelType.cache;
          } else if (roll < 0.75) {
            type = LevelType.exchange;
          } else if (roll < 0.85) {
            type = LevelType.elite;
          } else if (roll < 0.92) {
            type = LevelType.mystery;
          } else {
            type = LevelType.rest;
          }
        }

        // 生成更友好的关卡标题
        final title = _getLevelTitle(type, template.namePrefix, difficulty);
        // 生成怪物组合：偏向多人关卡
        List<String> programs = [];
        if (type == LevelType.boss) {
          // 从模板中挑选 Boss 类型的怪兽
          final bosses = template.possibleMonsters.where((id) => 
            systemDatabase[id]?.type == SystemType.boss
          ).toList();
          if (bosses.isNotEmpty) {
            programs = [bosses[random.nextInt(bosses.length)]];
          } else {
            programs = ['dragon']; // 兜底
          }
        } else if (type == LevelType.infiltration || type == LevelType.elite) {
          final baseCount = type == LevelType.elite ? 3 : 2;
          final extra = random.nextDouble() < 0.5 ? 1 : 0;
          final count = (baseCount + extra).clamp(2, 4);
          final desiredType = type == LevelType.elite ? SystemType.elite : SystemType.normal;
          int minLevel, maxLevel;
          switch (difficulty) {
            case 1: minLevel = 1; maxLevel = 2; break;
            case 2: minLevel = 1; maxLevel = 3; break;
            case 3: minLevel = 2; maxLevel = 4; break;
            case 4: minLevel = 3; maxLevel = 4; break;
            default: minLevel = 4; maxLevel = 4; break;
          }
          final pool = template.possibleMonsters.where((id) {
            final data = systemDatabase[id];
            if (data == null) return false;
            return data.type == desiredType && data.level >= minLevel && data.level <= maxLevel;
          }).toList();
          List<String> fallbackPool = systemDatabase.entries
              .where((e) => e.value.type == desiredType && e.value.level >= minLevel && e.value.level <= maxLevel)
              .map((e) => e.key)
              .toList();
          if (pool.isEmpty && fallbackPool.isEmpty) {
            // 放宽等级限制：允许任何等级的同类型怪
            fallbackPool = systemDatabase.entries
                .where((e) => e.value.type == desiredType)
                .map((e) => e.key)
                .toList();
          }
          // 如果仍为空，作为兜底：使用模板里任何怪（不按类型）
          List<String> usePool = pool.isNotEmpty ? pool : (fallbackPool.isNotEmpty ? fallbackPool : template.possibleMonsters);
          if (usePool.isEmpty) {
            usePool = (desiredType == SystemType.elite)
                ? ['orc_warrior', 'shadow_hunter', 'dark_mage', 'scythe_hand']
                : ['slime', 'goblin', 'skeleton', 'iron_dummy', 'echo_bug', 'spark_ball'];
          }
          for (int k = 0; k < count; k++) {
            programs.add(usePool[random.nextInt(usePool.length)]);
          }
        }

        // 计算更丰富的难度分布（1-5）
        int _depthBonus() {
          if (isFirstLayer) return -1;
          if (isLastLayer) return 2;
          final p = l / (layerCount - 1);
          if (p < 0.25) return -1;
          if (p < 0.5) return 0;
          if (p < 0.75) return 1;
          return 2;
        }
        int _typeBonus() {
          switch (type) {
            case LevelType.elite:
              return 1;
            case LevelType.exchange:
            case LevelType.rest:
              return -1;
            case LevelType.mystery:
              return random.nextBool() ? 1 : 0;
            case LevelType.cache:
              return 0;
            case LevelType.infiltration:
              return 0;
            case LevelType.boss:
              return 3;
          }
        }
        final jitter = [-1, 0, 0, 1][random.nextInt(4)];
        int nodeDiff = difficulty + _depthBonus() + _typeBonus() + jitter;
        if (type == LevelType.boss) nodeDiff = 5;
        nodeDiff = nodeDiff.clamp(1, 5);

        return LevelInfo(
          id: id,
          title: title,
          programIds: programs,
          type: type,
          difficulty: nodeDiff,
          nextLevelIndices: [], // 先初始化为空，后面统一生成连线
        );
      });
      layers.add(layerNodes);
    }

    // 统一生成连线逻辑，确保通路并支持自由选择
    for (int l = 0; l < layerCount - 1; l++) {
      final currentLayer = layers[l];
      final nextLayerNodes = layers[l + 1];
      
      for (int i = 0; i < currentLayer.length; i++) {
        final node = currentLayer[i];
        
        // 1. 确保每个节点至少连向下一层的一个节点
        // 使用一种相对平衡的分配方式，避免线太乱
        int primaryNext = (i * nextLayerNodes.length ~/ currentLayer.length) % nextLayerNodes.length;
        node.nextLevelIndices.add(primaryNext);

        // 2. 有概率多连一个相邻的节点，增加自由选择
        if (nextLayerNodes.length > 1) {
          if (random.nextDouble() < 0.5) {
            int secondaryNext = (primaryNext + 1) % nextLayerNodes.length;
            if (!node.nextLevelIndices.contains(secondaryNext)) {
              node.nextLevelIndices.add(secondaryNext);
            }
          }
          if (random.nextDouble() < 0.3) {
            int tertiaryNext = (primaryNext - 1 + nextLayerNodes.length) % nextLayerNodes.length;
            if (!node.nextLevelIndices.contains(tertiaryNext)) {
              node.nextLevelIndices.add(tertiaryNext);
            }
          }
        }
      }

      // 3. 反向检查：确保下一层的每个节点都有来源
      for (int j = 0; j < nextLayerNodes.length; j++) {
        bool hasSource = false;
        for (var node in currentLayer) {
          if (node.nextLevelIndices.contains(j)) {
            hasSource = true;
            break;
          }
        }
        if (!hasSource) {
          // 如果没有来源，从最近的上层节点连过来
          int closestSource = (j * currentLayer.length ~/ nextLayerNodes.length) % currentLayer.length;
          currentLayer[closestSource].nextLevelIndices.add(j);
        }
      }
    }

    return Nation(
      id: 'nation_$index',
      title: _getNationFriendlyTitle(template, index),
      description: '${template.descriptionBase}（尖塔网络）',
      difficulty: difficulty,
      shapeVertices: vertices,
      layers: layers,
      themeColor: template.themeColor,
    );
  }

  static String _getLevelTitle(LevelType type, String prefix, int diff) {
    final infiltrationNames = [
      '薄雾街口','灯塔小径','风鸣断桥','银灯巷','低语庭院','回声广场',
      '雾港栈桥','星辉坂道','霓虹长廊','回声甬道','光塔边缘','潮汐平台'
    ];
    final eliteNames = [
      '裂影堡','霜夜塔','星落庭','破晓门','铁潮岗',
      '磁涡城','玄霜壁','光弧庭','量子门','裂隙枢'
    ];
    final cacheNames = ['补给点','器械站','补给仓','休整处','维修舱','后勤点'];
    final exchangeNames = ['小摊位','货栈','商铺','交易点','数据柜','交换站'];
    final mysteryNames = ['奇遇点','偶发事件','未知之所','扭曲之门','随机扰动'];
    final restNames = ['篝火处','歇脚点','修复站','维保处','冷却间'];
    final bossNames = ['守望者','终幕者','领域主宰','审判者','序列枢纽'];
    final r = Random();
    switch (type) {
      case LevelType.infiltration:
        return infiltrationNames[r.nextInt(infiltrationNames.length)];
      case LevelType.elite:
        return eliteNames[r.nextInt(eliteNames.length)];
      case LevelType.cache:
        return cacheNames[r.nextInt(cacheNames.length)];
      case LevelType.exchange:
        return exchangeNames[r.nextInt(exchangeNames.length)];
      case LevelType.mystery:
        return mysteryNames[r.nextInt(mysteryNames.length)];
      case LevelType.rest:
        return restNames[r.nextInt(restNames.length)];
      case LevelType.boss:
        return '${prefix}${bossNames[r.nextInt(bossNames.length)]}';
    }
  }

  static String _getNationFriendlyTitle(NationTemplate template, int index) {
    final r = Random(index * 997);
    final neon = ['霓虹庭', '银灯街', '极光港', '光塔巷', '星辉城'];
    final wasteland = ['荒原谷', '风砂坍', '铁锈地', '残壁坡', '灰迹河'];
    final abyss = ['深渊岭', '影语原', '回声野', '裂幕境', '夜幕湾'];
    List<String> pool;
    switch (template.namePrefix) {
      case '霓虹':
        pool = neon;
        break;
      case '荒原':
        pool = wasteland;
        break;
      case '深渊':
        pool = abyss;
        break;
      default:
        pool = ['星幕域', '晓光域', '长夜城', '晨雾港'];
    }
    final name = pool[r.nextInt(pool.length)];
    return name;
  }

  /// 进入新国度
  static void enterNation(String nationId) {
    currentNationId = nationId;
    currentLayer = -1;
    currentLevelId = null;
    currentIndex = -1;
    defeatedIds.clear();
  }

  /// 完成当前国度
  static void completeCurrentNation() {
    if (currentNationId != null) {
      completedNationIds.add(currentNationId!);
    }
  }

  /// 是否所有国度都已通关
  static bool isAllNationsCompleted() {
    return completedNationIds.length == generatedNations.length;
  }

  static LevelInfo startFirstBattle() {
    final info = levelLayers[0][0]; // 默认进入第一个节点
    setCurrentLevel(info);
    return info;
  }

  static bool hasLayer(int layer) => layer >= 0 && layer < levelLayers.length;
  static List<LevelInfo> getLayer(int layer) => levelLayers[layer];

  static void setCurrentLevel(LevelInfo level) {
    currentLevelId = level.id;
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
    
    // 如果击败的是 Boss，标记当前国度完成
    for (final layer in levelLayers) {
      for (final level in layer) {
        if (level.id == id && level.type == LevelType.boss) {
          completeCurrentNation();
          return;
        }
      }
    }
  }

  static bool isDefeated(String id) {
    return defeatedIds.contains(id);
  }

  /// 检查当前国度是否已通关（击败了 Boss）
  static bool isCurrentNationFinished() {
    if (currentNationId == null) return false;
    // 查找当前国度的 Boss 节点
    for (final layer in levelLayers) {
      for (final level in layer) {
        if (level.type == LevelType.boss && defeatedIds.contains(level.id)) {
          return true;
        }
      }
    }
    return false;
  }

  static List<int> allowedNextIndices() {
    if (currentLevelId == null) {
      // 如果没有进入任何节点，则允许进入第一层的所有节点
      if (levelLayers.isEmpty) return [];
      return List.generate(levelLayers[0].length, (i) => i);
    }
    if (currentLayer < 0 || currentLayer >= levelLayers.length) return [];
    final currentLevel = levelLayers[currentLayer][currentIndex];
    return currentLevel.nextLevelIndices;
  }

  static void resetRunData() {
    currentLayer = -1;
    currentLevelId = null;
    currentIndex = -1;
    defeatedIds.clear();
    currentNationId = null;
    completedNationIds.clear();
    generatedNations = [];
  }
}
