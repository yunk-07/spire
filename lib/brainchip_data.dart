enum BrainChipSuite {
  military,    // 军事级：侧重算力与进攻
  medical,     // 医疗级：侧重生命与防御
  commercial,  // 商业级：侧重资源与金钱（如果有的话，或者摸牌）
  experimental,// 实验级：特殊奇特的效果
  illegal      // 非法级：高风险高回报
}

class BrainChip {
  final String id;
  final String name;
  final int level;
  final String? effect; // 使用 DSL 描述效果，例如 'strength 2'
  final int themeColor; // ARGB hex color
  final String description;
  final BrainChipSuite suite; // 脑机系列
  
  const BrainChip({
    required this.id,
    required this.name,
    required this.level,
    this.effect,
    required this.themeColor,
    required this.description,
    this.suite = BrainChipSuite.commercial,
  });

  String get suiteName {
    switch (suite) {
      case BrainChipSuite.military: return "军事级";
      case BrainChipSuite.medical: return "医疗级";
      case BrainChipSuite.commercial: return "商业级";
      case BrainChipSuite.experimental: return "实验级";
      case BrainChipSuite.illegal: return "非法级";
    }
  }

  int get suiteIconCode {
    switch (suite) {
      case BrainChipSuite.military: return 0xe32a; // military_tech
      case BrainChipSuite.medical: return 0xe3f1; // medical_services
      case BrainChipSuite.commercial: return 0xe116; // business_center
      case BrainChipSuite.experimental: return 0xeb3f; // science
      case BrainChipSuite.illegal: return 0xe566; // skull / report_problem
    }
  }
}

const List<BrainChip> brainChipPool = [
  BrainChip(
  id: "accel_1_0",
  name: "加速运算脑机1.0",
  level: 1,
  effect: "strength 2",
  themeColor: 0xFF26F5E2, // 明亮商业青
  description: "在开局时直接提升 2 点算力，加速所有指令执行。",
  suite: BrainChipSuite.commercial,
),

BrainChip(
  id: "accel_2_0",
  name: "加速运算脑机2.0",
  level: 2,
  effect: "strength 4",
  themeColor: 0xFF1E88E5, // 军用冷蓝
  description: "在开局时直接提升 4 点算力，加速所有指令执行。",
  suite: BrainChipSuite.military,
),

BrainChip(
  id: "ann_replacement",
  name: "ANN接替思维脑机",
  level: 3,
  effect: "passive_draw_on_use",
  themeColor: 0xFF8E24AA, // 实验紫
  description: "当手牌小于7，每使用一张牌摸一张牌。",
  suite: BrainChipSuite.experimental,
),

// --- 军事级 ---
BrainChip(
  id: "combat_core_v1",
  name: "战斗核心 V1",
  level: 2,
  effect: "strength 3",
  themeColor: 0xFF546E7A, // 钛灰钢
  description: "专为极端环境设计的战斗处理核心。提供 3 点基础算力。",
  suite: BrainChipSuite.military,
),

BrainChip(
  id: "overclock_module",
  name: "超频驱动模块",
  level: 3,
  effect: "strength 5; self_damage 3",
  themeColor: 0xFFFF9800, // 战术橙
  description: "强制突破算力限制。提供 5 点算力，但每场战斗开始时自损 3 点生命。",
  suite: BrainChipSuite.military,
),

// --- 医疗级 ---
BrainChip(
  id: "nano_repair_v1",
  name: "纳米修复集群 V1",
  level: 1,
  effect: "max_hp_up 1",
  themeColor: 0xFF66BB6A, // 柔生命绿
  description: "微型纳米机器人持续修复机体。每局增加 1 点生命上限。",
  suite: BrainChipSuite.medical,
),

BrainChip(
  id: "vital_booster",
  name: "生命体征增强器",
  level: 2,
  effect: "max_hp_up 2; heal 10",
  themeColor: 0xFF00C853, // 强化医疗绿
  description: "全面增强生命体征。每局恢复 10 点生命，增加 2 点生命上限。",
  suite: BrainChipSuite.medical,
),

// --- 实验级 ---
BrainChip(
  id: "glitch_processor",
  name: "故障频率处理器",
  level: 2,
  effect: "passive_energy_chance_50",
  themeColor: 0xFFD500F9, // 故障亮紫
  description: "利用系统故障进行运算。每回合有 50% 概率额外获得 1 点能量。",
  suite: BrainChipSuite.experimental,
),

BrainChip(
  id: "quantum_link",
  name: "量子链路接口",
  level: 4,
  effect: "quantum_link",
  themeColor: 0xFF3D5AFE, // 深量子蓝
  description: "跨维度数据链路。每回合第一张消耗 2 点能量的卡牌变为 0 消耗。",
  suite: BrainChipSuite.experimental,
),

// --- 非法级 ---
BrainChip(
  id: "void_reaper",
  name: "虚空收割者",
  level: 5,
  effect: "strength 30; permanent_max_hp_mult 0.5",
  themeColor: 0xFFC62828, // 保持深猩红
  description: "极其罕见的禁忌组件。提供 30 点算力，但最大生命值减半（仅限装备时触发一次）。",
  suite: BrainChipSuite.illegal,
),


];

final Map<String, BrainChip> brainChipDatabase = {
  for (var chip in brainChipPool) chip.id: chip,
};
