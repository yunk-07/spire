// character_data.dart
import 'package:flutter/material.dart';

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
  fa,
}

/// 角色数据模型
class CharacterData {
  final String id;
  final String name;
  final CharacterClass characterClass;
  final IconData icon;
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
    required this.icon,
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
    icon: Icons.favorite,
    maxHp: 100,
    startingDeck: [
      "xueye_strike",
      "xueye_strike",
      "xueye_strike",
      "xueye_defend",
      "xueye_defend",
      "xueye_siphon",
      "xueye_siphon",
      "ritual",
      "burning_slash",
      "ignite",
      "supercomputer_f",
      "capacity_trim",
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
    icon: Icons.account_tree,
    maxHp: 120,
    startingDeck: [
      "lin_strike",
      "lin_strike",
      "lin_strike",
      "lin_defend",
      "lin_defend",
      "lin_defend",
      "repair_module",
      "shield_boost",
      "assemble",
      "fade_step",
      "peek_future",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 6,
    description: "平衡性接入单元，具有优秀的持久性与冗余数据处理能力。",
    passives: [
      "【冗余利用】每弃掉一张牌，获得 2 点防火墙（格挡）。",
      "【稳态增压】每使用一张牌，获得 5 点临时算力。",
    ],
  ),

  /// =========================
  /// 浪潮 —— 能量 / 爆发回合
  /// =========================
  "langchao": CharacterData(
    id: "langchao",
    name: "浪潮",
    characterClass: CharacterClass.langchao,
    icon: Icons.waves,
    maxHp: 95,
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
      "data_broadcast",
      "matrix_sweep",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 6,
    description: "高频脉冲载体，能够瞬间产生大量数据流覆盖目标。",
    passives: [
      "【涌动】当手牌为 0 时，恢复 2 能量并摸 2 张牌。",
    ],
  ),

  /// =========================
  /// 剑刃 —— 高费 / 终结技
  /// =========================
  "jianren": CharacterData(
    id: "jianren",
    name: "剑刃",
    characterClass: CharacterClass.jianren,
    icon: Icons.colorize,
    maxHp: 166,
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
      "fortify_wall",
      "nano_plating",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "终端突破型，擅长快速破防并直击核心。",
    passives: [
      "【弱点洞察】攻击无护盾。",
      "【终结斩】目标无护盾时伤害+24%。",
      "【不灭壁甲】每回合获得 1 层坚固；击败敌人时恢复 50 生命。",
    ],
  ),

  /// =========================
  /// 焰心 —— 高风险爆发
  /// =========================
  "yanxin": CharacterData(
    id: "yanxin",
    name: "焰心",
    characterClass: CharacterClass.yanxin,
    icon: Icons.local_fire_department,
    maxHp: 82,
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
      "capacity_upgrade",
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
    name: "影逐",
    characterClass: CharacterClass.yingshi,
    icon: Icons.visibility_off,
    maxHp: 80,
    startingDeck: [
      "yingshi_strike",
      "yingshi_strike",
      "yingshi_strike",
      "yingshi_defend",
      "yingshi_defend",
      "yingshi_defend",
      "fade_step",
      "curse_mark",
      "peek_future",
      "chaos_logic",
      "glitch_step",
    ],
    minDrawPerTurn: 4,
    maxDrawPerTurn: 7,
    description: "以“临时算力”驱动的追踪者，可将受损与终结转化为短时爆发资源。",
    passives: [
      "【隐匿追击】受到生命值伤害后，按 5:1 转化为临时算力；回合开始临时算力 -5；护盾被破当下获得 16 临时算力。",
      "【影】击杀敌人时，获得其最大生命值 1:1 的临时算力。",
      "【孤影】若只有一个敌人，开局获得 24 临时算力并得到 1 层脆弱（仅一次）。",
      "临时算力与算力同效，提升造成的伤害，但会快速衰减。",
    ],
  ),

  /// =========================
  /// 几何 —— 构筑 / 防御
  /// =========================
  "jihe": CharacterData(
    id: "jihe",
    name: "几何",
    characterClass: CharacterClass.jihe,
    icon: Icons.category,
    maxHp: 90,
    startingDeck: [
      "jihe_strike",
      "jihe_strike",
      "jihe_strike",
      "jihe_defend",
      "jihe_defend",
      "jihe_defend",
      "shield_boost",
      "repair_module",
      "fortify_wall",
      "capacity_upgrade",
      "logic_gate",
      "predator_program",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "精密计算核心，擅长建立结构化的逻辑链路。",
    passives: [
      "【结构链路】当使用的牌与上一张牌类别（suite）相同时，恢复 1 能量并摸 1 张牌。",
    ],
  ),

  /// =========================
  /// 虚行 —— 随机 / 混沌
  /// =========================
  "xuxing": CharacterData(
    id: "xuxing",
    name: "虚行",
    characterClass: CharacterClass.xuxing,
    icon: Icons.blur_on,
    maxHp: 94,
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
      "data_broadcast",
      "block_wall",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 6,
    description: "虚空行者，能够操纵不稳定的数据碎片进行攻击。",
    passives: [
      "【虚空共鸣】每使用一张“量子”卡牌，随机使一名敌人获得 1 层恶意代码（诅咒）。",
    ],
  ),
  /// =========================
  /// 法 —— 规则扩散 / 群体化
  /// =========================
  "fa": CharacterData(
    id: "fa",
    name: "法",
    characterClass: CharacterClass.fa,
    icon: Icons.gavel,
    maxHp: 95,
    startingDeck: [
      "data_broadcast",
      "matrix_sweep",
      "global_format",
      "fa_weaken",
      "fa_cascade",
      "neural_interface",
      "peek_future",
      "energy_boost",
      "logic_gate",
      "predator_program",
      "hardened_shell",
      "defend_2",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 6,
    description: "将单体规则扩散为群体，并强化既有范围指令的效能。",
    passives: [
      "【群体化规约】所有单体伤害牌改为群体伤害；群体伤害牌伤害 +25%。",
      "【初始调谐】开局获得按敌人数量计算的虚弱：每个敌人 +1 层。",
    ],
  ),
};
