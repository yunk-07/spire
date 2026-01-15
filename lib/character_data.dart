// character_data.dart

/// 角色职业枚举
enum CharacterClass {
  xueye,
  lin,
  langchao,
  jianren,
  yanxin,
  yingshi,
  jihe,
  xuxing,
}

/// 角色数据模型
class CharacterData {
  final String id;
  final String name;
  final CharacterClass characterClass;
  final int maxHp;
  final List<String> startingDeck;
  final int minDrawPerTurn;
  final int maxDrawPerTurn;
  final String description;
  final List<String> passives; // 关键区域：被动技能描述

  const CharacterData({
    required this.id,
    required this.name,
    required this.characterClass,
    required this.maxHp,
    required this.startingDeck,
    required this.minDrawPerTurn,
    required this.maxDrawPerTurn,
    required this.description,
    this.passives = const [],
  });
}

/// 角色数据库
const Map<String, CharacterData> characterDatabase = {
  /// =========================
  /// 血液 —— 自残 / 力量成长
  /// =========================
  "xueye": CharacterData(
    id: "xueye",
    name: "血液",
    characterClass: CharacterClass.xueye,
    maxHp: 85,
    startingDeck: [
      "xueye_strike",
      "xueye_strike",
      "xueye_strike",
      "xueye_defend",
      "xueye_defend",
      "xueye_siphon",
      "xueye_siphon",
      "bash",
      "ritual",
      "burning_slash",
      "ignite",
      "supercomputer_f",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "核心逻辑模块，通过牺牲系统稳定性换取极高吞吐量。",
    passives: [
      "【生命回收】每次使用卡牌恢复 1 点生命值。",
      "【血债血偿】生命值越低，造成的伤害越高（基于损失生命值获得额外算力）。",
    ],
  ),

  /// =========================
  /// 林 —— 抽牌 / 稳定节奏
  /// =========================
  "lin": CharacterData(
    id: "lin",
    name: "林",
    characterClass: CharacterClass.lin,
    maxHp: 70,
    startingDeck: [
      "lin_strike",
      "lin_strike",
      "lin_strike",
      "lin_defend",
      "lin_defend",
      "lin_defend",
      "survivor",
      "sneaky_strike",
      "assemble",
      "fade_step",
      "peek_future",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 6,
    description: "平衡性接入单元，具有优秀的持久性与冗余数据处理能力。",
    passives: [
      "【冗余利用】每弃掉一张牌，获得 2 点防火墙（格挡）。",
    ],
  ),

  /// =========================
  /// 浪潮 —— 能量 / 爆发回合
  /// =========================
  "langchao": CharacterData(
    id: "langchao",
    name: "浪潮",
    characterClass: CharacterClass.langchao,
    maxHp: 75,
    startingDeck: [
      "langchao_strike",
      "langchao_strike",
      "langchao_strike",
      "langchao_defend",
      "langchao_defend",
      "langchao_defend",
      "dualcast",
      "energy_boost",
      "overclock",
      "double_hit",
      "double_hit",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 6,
    description: "高频脉冲载体，能够瞬间产生大量数据流覆盖目标。",
    passives: [
      "【涌动】当手牌为 0 时，恢复 2 宽带并摸 2 张牌。",
    ],
  ),

  /// =========================
  /// 剑刃 —— 高费 / 终结技
  /// =========================
  "jianren": CharacterData(
    id: "jianren",
    name: "剑刃",
    characterClass: CharacterClass.jianren,
    maxHp: 72,
    startingDeck: [
      "jianren_strike",
      "jianren_strike",
      "jianren_strike",
      "jianren_defend",
      "jianren_defend",
      "jianren_defend",
      "bash",
      "eruption",
      "heavy_blade",
      "defensive_stance",
      "double_hit",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "终端突破型，擅长快速破防并直击核心。",
    passives: [
      "【弱点洞察】攻击无护盾。",
      "【终结斩】目标无护盾时伤害+24%。",
    ],
  ),

  /// =========================
  /// 焰心 —— 高风险爆发
  /// =========================
  "yanxin": CharacterData(
    id: "yanxin",
    name: "焰心",
    characterClass: CharacterClass.yanxin,
    maxHp: 70,
    startingDeck: [
      "yanxin_strike",
      "yanxin_strike",
      "yanxin_strike",
      "yanxin_defend",
      "yanxin_defend",
      "yanxin_defend",
      "burning_slash",
      "ignite",
      "ritual",
      "overclock",
      "bludgeon",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "逻辑炸弹投送器，通过过载计算产生高温热量并引燃目标。",
    passives: [
      "【过载热能】回合结束时，每点剩余能量随机给敌人施加 1 层火焰；火焰会在回合结束时清除护盾。",
      "【热能回收】使用能量累积热量进度；点击热量爆发将全部进度按 1:1 分摊为伤害并同等值恢复玩家生命值。",
    ],
  ),

  /// =========================
  /// 影蚀 —— 潜行 / 爆发
  /// =========================
  "yingshi": CharacterData(
    id: "yingshi",
    name: "影蚀",
    characterClass: CharacterClass.yingshi,
    maxHp: 68,
    startingDeck: [
      "yingshi_strike",
      "yingshi_strike",
      "yingshi_strike",
      "yingshi_defend",
      "yingshi_defend",
      "yingshi_defend",
      "sneaky_strike",
      "fade_step",
      "curse_mark",
      "peek_future",
      "supercomputer_f",
    ],
    minDrawPerTurn: 4,
    maxDrawPerTurn: 7,
    description: "潜行侦察型，擅长在数据流中隐藏行踪并进行精准打击。",
    passives: [
      "【隐匿打击】如果本回合未受到生命值损伤，下回合开始时额外摸 1 张牌。",
    ],
  ),

  /// =========================
  /// 几何 —— 构筑 / 防御
  /// =========================
  "jihe": CharacterData(
    id: "jihe",
    name: "几何",
    characterClass: CharacterClass.jihe,
    maxHp: 80,
    startingDeck: [
      "jihe_strike",
      "jihe_strike",
      "jihe_strike",
      "jihe_defend",
      "jihe_defend",
      "jihe_defend",
      "assemble",
      "defensive_stance",
      "block_wall",
      "repair_module",
      "shield_boost",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "精密计算核心，擅长建立结构化的逻辑链路。",
    passives: [
      "【结构链路】当使用的牌与上一张牌类别（suite）相同时，恢复 1 宽带并摸 1 张牌。",
    ],
  ),

  /// =========================
  /// 虚行 —— 随机 / 混沌
  /// =========================
  "xuxing": CharacterData(
    id: "xuxing",
    name: "虚行",
    characterClass: CharacterClass.xuxing,
    maxHp: 74,
    startingDeck: [
      "xuxing_strike",
      "xuxing_strike",
      "xuxing_strike",
      "xuxing_defend",
      "xuxing_defend",
      "xuxing_defend",
      "dualcast",
      "quantum_burst",
      "chaos_logic",
      "glitch_step",
      "void_slash",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 6,
    description: "虚空行者，能够操纵不稳定的数据碎片进行攻击。",
    passives: [
      "【虚空共鸣】每使用一张“量子”卡牌，随机使一名敌人获得 1 层恶意代码（诅咒）。",
    ],
  ),
};
