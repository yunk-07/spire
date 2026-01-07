// character_data.dart

/// 角色职业枚举
enum CharacterClass { ironclad, silent, defect, watcher }

/// 角色数据模型
class CharacterData {
  final String id;
  final String name;
  final CharacterClass characterClass;
  final int maxHp;
  final List<String> startingDeck; // 初始摸牌堆
  final int minDrawPerTurn; // 每回合最少摸牌数
  final int maxDrawPerTurn; // 每回合最多摸牌数
  final String description;
  
  const CharacterData({
    required this.id,
    required this.name,
    required this.characterClass,
    required this.maxHp,
    required this.startingDeck,
    required this.minDrawPerTurn,
    required this.maxDrawPerTurn,
    required this.description,
  });
}

/// 角色数据库
const Map<String, CharacterData> characterDatabase = {
  "ironclad": CharacterData(
    id: "ironclad",
    name: "铁甲战士",
    characterClass: CharacterClass.ironclad,
    maxHp: 80,
    startingDeck: ["strike_1", "strike_1", "strike_1", "strike_1", "strike_1", "defend_1", "defend_1", "defend_1", "defend_1", "bash"],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "强大的战士，擅长近战攻击和防御",
  ),
  "silent": CharacterData(
    id: "silent",
    name: "静默猎手",
    characterClass: CharacterClass.silent,
    maxHp: 70,
    startingDeck: ["strike_1", "strike_1", "strike_1", "strike_1", "strike_1", "defend_1", "defend_1", "defend_1", "defend_1", "survivor"],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "敏捷的刺客，擅长毒药和连击",
  ),
  "defect": CharacterData(
    id: "defect",
    name: "故障机器人",
    characterClass: CharacterClass.defect,
    maxHp: 75,
    startingDeck: ["strike_1", "strike_1", "strike_1", "strike_1", "strike_1", "defend_1", "defend_1", "defend_1", "defend_1", "dualcast"],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "机械造物，擅长能量操控和轨道球",
  ),
  "watcher": CharacterData(
    id: "watcher",
    name: "观察者",
    characterClass: CharacterClass.watcher,
    maxHp: 72,
    startingDeck: ["strike_1", "strike_1", "strike_1", "strike_1", "strike_1", "defend_1", "defend_1", "defend_1", "defend_1", "eruption"],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "神秘的修行者，擅长姿态切换和神圣力量",
  ),
};