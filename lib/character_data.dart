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
  /// =========================
  /// 血液 —— 自残 / 力量成长
  /// =========================
  "xueye": CharacterData(
    id: "xueye",
    name: "血液",
    characterClass: CharacterClass.xueye,
    maxHp: 80,
    startingDeck: [
      "strike_1",
      "strike_1",
      "strike_1",
      "defend_1",
      "defend_1",
      "defend_1",
      "bash",
      "ritual",
      "burning_slash",
      "defensive_stance",
      "supercomputer_f",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "核心逻辑模块，通过牺牲系统稳定性换取极高吞吐量。",
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
      "strike_1",
      "strike_1",
      "strike_1",
      "defend_1",
      "defend_1",
      "defend_1",
      "survivor",
      "sneaky_strike",
      "assemble",
      "fade_step",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 6,
    description: "平衡性接入单元，具有优秀的持久性与冗余数据处理能力。",
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
      "strike_1",
      "strike_1",
      "defend_1",
      "defend_1",
      "defend_1",
      "dualcast",
      "energy_boost",
      "overclock",
      "assemble",
      "double_hit",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 6,
    description: "高频脉冲载体，能够瞬间产生大量数据流覆盖目标。",
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
      "strike_1",
      "strike_1",
      "defend_1",
      "defend_1",
      "defend_1",
      "eruption",
      "heavy_blade",
      "double_hit",
      "defensive_stance",
      "phase_shift",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "破译专家，专注于在短时间内突破目标的底层防火墙。",
  ),

  /// =========================
  /// 焰心 —— 高风险爆发
  /// =========================
  "yanxin": CharacterData(
    id: "yanxin",
    name: "焰心",
    characterClass: CharacterClass.yanxin,
    maxHp: 65,
    startingDeck: [
      "strike_1",
      "strike_1",
      "burning_slash",
      "burning_slash",
      "ignite",
      "ritual",
      "defend_1",
      "defend_1",
      "overclock",
      "heavy_blade",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 5,
    description: "过载核心，通过超频系统内核实现毁灭性的攻击载荷。",
  ),

  /// =========================
  /// 影誓 —— 控制 / 安全
  /// =========================
  "yingshi": CharacterData(
    id: "yingshi",
    name: "影誓",
    characterClass: CharacterClass.yingshi,
    maxHp: 68,
    startingDeck: [
      "strike_1",
      "strike_1",
      "defend_1",
      "defend_1",
      "fade_step",
      "weaken",
      "curse_mark",
      "sneaky_strike",
      "assemble",
      "phase_shift",
    ],
    minDrawPerTurn: 4,
    maxDrawPerTurn: 6,
    description: "以削弱与节奏掌控取胜的暗影行者。",
  ),

  /// =========================
  /// 机核 —— 成长 / 后期
  /// =========================
  "jihe": CharacterData(
    id: "jihe",
    name: "机核",
    characterClass: CharacterClass.jihe,
    maxHp: 78,
    startingDeck: [
      "strike_1",
      "strike_1",
      "defend_1",
      "defend_1",
      "assemble",
      "assemble",
      "core_module",
      "core_module",
      "defensive_stance",
      "double_hit",
    ],
    minDrawPerTurn: 3,
    maxDrawPerTurn: 6,
    description: "迭代引擎，能够不断优化自身逻辑架构，实现指数级性能增长。",
  ),

  /// =========================
  /// 虚行者 —— 操作 / 防御
  /// =========================
  "xuxing": CharacterData(
    id: "xuxing",
    name: "虚行者",
    characterClass: CharacterClass.xuxing,
    maxHp: 70,
    startingDeck: [
      "infinite_loop",
      "defend_1",
      "defend_1",
      "fade_step",
      "phase_shift",
      "vanish",
      "peek_future",
      "assemble",
      "sneaky_strike",
      "double_hit",
    ],
    minDrawPerTurn: 4,
    maxDrawPerTurn: 7,
    description: "幽灵代码，利用系统漏洞进行不可预测的位移与拦截。",
  ),
};
