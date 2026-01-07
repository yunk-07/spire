// card_data.dart

/// 卡牌类型枚举
enum CardType { attack, block, skill, power }

/// 卡牌数据模型
class CardData {
  final String id;
  final String name;
  final CardType type;
  final int cost;
  final int value;
  final int level;
  final String? effect; // DSL效果描述

  const CardData({
    required this.id,
    required this.name,
    required this.type,
    required this.cost,
    required this.value,
    required this.level,
    this.effect,
  });
}

/// 效果执行回调函数类型
typedef EffectCallback =
    void Function(String effect, CardData card, dynamic target, dynamic battle);

/// 卡牌效果DSL解析器（基础接口）
class CardEffect {
  static EffectCallback? _executor;

  /// 设置效果执行器
  static void setExecutor(EffectCallback executor) {
    _executor = executor;
  }

  /// 执行效果
  static void execute(
    String effect,
    CardData card,
    dynamic target,
    dynamic battle,
  ) {
    _executor?.call(effect, card, target, battle);
  }
}

/// 卡牌数据库
const Map<String, CardData> cardDatabase = {
  "strike_1": CardData(
    id: "strike_1",
    name: "打击",
    type: CardType.attack,
    cost: 1,
    value: 6,
    level: 1,
    effect: "damage 6",
  ),
  "strike_2": CardData(
    id: "strike_2",
    name: "打击+",
    type: CardType.attack,
    cost: 1,
    value: 9,
    level: 2,
    effect: "damage 9",
  ),
  "block_1": CardData(
    id: "block_1",
    name: "防御",
    type: CardType.block,
    cost: 1,
    value: 5,
    level: 1,
    effect: "block 5",
  ),
  "bash": CardData(
    id: "bash",
    name: "重击",
    type: CardType.attack,
    cost: 2,
    value: 8,
    level: 1,
    effect: "damage 8 vulnerable 2",
  ),
  "defend_1": CardData(
    id: "defend_1",
    name: "防御",
    type: CardType.block,
    cost: 1,
    value: 5,
    level: 1,
    effect: "block 5",
  ),
  "defend_plus": CardData(
    id: "defend_plus",
    name: "防御+",
    type: CardType.block,
    cost: 1,
    value: 8,
    level: 2,
    effect: "block 8",
  ),
  "energy_boost": CardData(
    id: "energy_boost",
    name: "能量提升",
    type: CardType.skill,
    cost: 0,
    value: 0,
    level: 1,
    effect: "energy 1 draw 1",
  ),
  "survivor": CardData(
    id: "survivor",
    name: "生存者",
    type: CardType.skill,
    cost: 1,
    value: 0,
    level: 1,
    effect: "block 8 draw 1",
  ),
  "dualcast": CardData(
    id: "dualcast",
    name: "双重施法",
    type: CardType.skill,
    cost: 1,
    value: 0,
    level: 1,
    effect: "damage 16",
  ),
  "eruption": CardData(
    id: "eruption",
    name: "爆发",
    type: CardType.attack,
    cost: 2,
    value: 9,
    level: 1,
    effect: "damage 9",
  ),
};
