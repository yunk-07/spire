// level_data.dart
// 作用：定义地图关卡数据，支持动态生成的国度、不规则形状、以及节点间的走线连接
import 'dart:math';
import 'package:flutter/painting.dart';

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
    possibleMonsters: ['slime', 'goblin'],
    themeColor: Color(0xFF6CE4FF),
  ),
  NationTemplate(
    namePrefix: '荒原',
    descriptionBase: '尖塔下的荒原带，荒废的数据垃圾场中隐藏被遗忘的重型协议。',
    possibleMonsters: ['skeleton', 'orc_warrior'],
    themeColor: Color(0xFFFFA726),
  ),
  NationTemplate(
    namePrefix: '深渊',
    descriptionBase: '尖塔阴影下的深渊域，不确定性极高的深层网络，逻辑在此发生扭曲。',
    possibleMonsters: ['dark_mage', 'dragon'],
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

        return LevelInfo(
          id: id,
          title: _getLevelTitle(type, template.namePrefix, difficulty),
          programIds: type == LevelType.boss 
              ? ['dragon'] 
              : (type == LevelType.infiltration || type == LevelType.elite 
                  ? [template.possibleMonsters[random.nextInt(template.possibleMonsters.length)]] 
                  : []),
          type: type,
          difficulty: type == LevelType.elite ? difficulty + 1 : difficulty,
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
      title: '尖塔·${template.namePrefix}扇区-$index',
      description: '${template.descriptionBase}（尖塔网络）',
      difficulty: difficulty,
      shapeVertices: vertices,
      layers: layers,
      themeColor: template.themeColor,
    );
  }

  static String _getLevelTitle(LevelType type, String prefix, int diff) {
    switch (type) {
      case LevelType.infiltration: return '$prefix渗透·级${diff}';
      case LevelType.elite: return '$prefix高危·级${diff + 1}';
      case LevelType.cache: return '数据缓存站';
      case LevelType.exchange: return '数据交易所';
      case LevelType.mystery: return '未知扰动点';
      case LevelType.rest: return '逻辑修复站';
      case LevelType.boss: return '$prefix核心·守护程序';
    }
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
}
