// monster_data.dart

enum SystemType { normal, elite, boss }

enum BuffKind { weak, vulnerable, curse }

class MonsterSkill {
  final String id;
  final String name;
  final double chance;
  final BuffKind? buff;
  final int stacks;
  const MonsterSkill({
    required this.id,
    required this.name,
    required this.chance,
    this.buff,
    this.stacks = 0,
  });
}

class SecurityProgram {
  final String id;
  final String name;
  final SystemType type;
  final int maxHp;
  final int baseDamage;
  final int damageMin;
  final int damageMax;
  final String description;
  final List<MonsterSkill> skills;
  const SecurityProgram({
    required this.id,
    required this.name,
    required this.type,
    required this.maxHp,
    required this.baseDamage,
    required this.damageMin,
    required this.damageMax,
    required this.description,
    this.skills = const [],
  });
}

/// 系统防护程序数据库
const Map<String, SecurityProgram> systemDatabase = {
  "slime": SecurityProgram(
    id: "slime",
    name: "粘滞碎片",
    type: SystemType.normal,
    maxHp: 40,
    baseDamage: 8,
    damageMin: 6,
    damageMax: 10,
    description: "一团具有粘性的数据残留，会拖慢系统的响应速度",
    skills: [
      MonsterSkill(id: "jam", name: "数据粘附", chance: 0.3, buff: BuffKind.vulnerable, stacks: 1),
    ],
  ),
  "goblin": SecurityProgram(
    id: "goblin",
    name: "窥探程序",
    type: SystemType.normal,
    maxHp: 30,
    baseDamage: 10,
    damageMin: 8,
    damageMax: 12,
    description: "细小且灵活的程序，在系统角落里寻找任何可利用的缝隙",
    skills: [
      MonsterSkill(id: "probe", name: "漏洞侦察", chance: 0.35, buff: BuffKind.vulnerable, stacks: 1),
      MonsterSkill(id: "strain", name: "指令干扰", chance: 0.25, buff: BuffKind.weak, stacks: 1),
    ],
  ),
  "skeleton": SecurityProgram(
    id: "skeleton",
    name: "废弃指令",
    type: SystemType.normal,
    maxHp: 25,
    baseDamage: 12,
    damageMin: 10,
    damageMax: 14,
    description: "早已被淘汰的旧版代码，即便残破不堪仍在机械地执行最后的任务",
    skills: [
      MonsterSkill(id: "infect", name: "代码侵蚀", chance: 0.25, buff: BuffKind.curse, stacks: 1),
    ],
  ),
  "orc_warrior": SecurityProgram(
    id: "orc_warrior",
    name: "重装守卫",
    type: SystemType.elite,
    maxHp: 60,
    baseDamage: 15,
    damageMin: 13,
    damageMax: 18,
    description: "拥有高强度外壳的防御程序，是保护核心的第一道坚实防线",
    skills: [
      MonsterSkill(id: "isolate", name: "强力阻截", chance: 0.35, buff: BuffKind.weak, stacks: 2),
      MonsterSkill(id: "blast", name: "冲击波", chance: 0.25),
    ],
  ),
  "dark_mage": SecurityProgram(
    id: "dark_mage",
    name: "幽暗影",
    type: SystemType.elite,
    maxHp: 45,
    baseDamage: 18,
    damageMin: 16,
    damageMax: 20,
    description: "如阴影般潜伏在内存深处，能悄无声息地夺走系统的活力",
    skills: [
      MonsterSkill(id: "drain", name: "能量抽取", chance: 0.3, buff: BuffKind.curse, stacks: 2),
    ],
  ),
  "dragon": SecurityProgram(
    id: "dragon",
    name: "裁决者",
    type: SystemType.boss,
    maxHp: 150,
    baseDamage: 25,
    damageMin: 22,
    damageMax: 30,
    description: "系统最高层级的执行者，拥有决定任何数据生死存亡的终极权力",
    skills: [
      MonsterSkill(id: "lock", name: "权限封锁", chance: 0.4, buff: BuffKind.curse, stacks: 2),
      MonsterSkill(id: "pressure", name: "系统压制", chance: 0.3, buff: BuffKind.weak, stacks: 2),
      MonsterSkill(id: "expose", name: "弱点标记", chance: 0.3, buff: BuffKind.vulnerable, stacks: 2),
    ],
  ),
  // 新增更易理解和顺口的怪兽
  "echo_bug": SecurityProgram(
    id: "echo_bug",
    name: "回响单元",
    type: SystemType.normal,
    maxHp: 35,
    baseDamage: 8,
    damageMin: 6,
    damageMax: 10,
    description: "不断重复接收到的信号，造成严重的逻辑循环干扰",
    skills: [
      MonsterSkill(id: "repeat", name: "指令重放", chance: 0.3, buff: BuffKind.weak, stacks: 1),
    ],
  ),
  "spark_ball": SecurityProgram(
    id: "spark_ball",
    name: "电脉冲",
    type: SystemType.normal,
    maxHp: 30,
    baseDamage: 12,
    damageMin: 10,
    damageMax: 14,
    description: "极度不稳定的能量球，任何接触都可能导致系统瞬间过载",
    skills: [
      MonsterSkill(id: "shock", name: "高压脉冲", chance: 0.4, buff: BuffKind.vulnerable, stacks: 1),
    ],
  ),
  "iron_dummy": SecurityProgram(
    id: "iron_dummy",
    name: "铁甲模块",
    type: SystemType.normal,
    maxHp: 55,
    baseDamage: 6,
    damageMin: 4,
    damageMax: 8,
    description: "笨重但极其坚固的冗余模块，常被用作物理屏障",
    skills: [
      MonsterSkill(id: "heavy_slam", name: "重力冲击", chance: 0.2, buff: BuffKind.weak, stacks: 2),
    ],
  ),
  "shadow_hunter": SecurityProgram(
    id: "shadow_hunter",
    name: "潜行猎手",
    type: SystemType.elite,
    maxHp: 75,
    baseDamage: 18,
    damageMin: 15,
    damageMax: 22,
    description: "专门猎杀异常数据的暗杀程序，擅长从视觉死角发起攻击",
    skills: [
      MonsterSkill(id: "backstab", name: "隐蔽突击", chance: 0.4, buff: BuffKind.vulnerable, stacks: 2),
      MonsterSkill(id: "hide", name: "掩蔽模式", chance: 0.2, buff: BuffKind.weak, stacks: 1),
    ],
  ),
  "scythe_hand": SecurityProgram(
    id: "scythe_hand",
    name: "收割指令",
    type: SystemType.elite,
    maxHp: 85,
    baseDamage: 20,
    damageMin: 18,
    damageMax: 24,
    description: "挥舞着巨大的清理工具，将一切不符合规范的代码统统切碎",
    skills: [
      MonsterSkill(id: "reap", name: "逻辑清理", chance: 0.35, buff: BuffKind.curse, stacks: 1),
    ],
  ),
  "grand_manager": SecurityProgram(
    id: "grand_manager",
    name: "主控核心",
    type: SystemType.boss,
    maxHp: 200,
    baseDamage: 30,
    damageMin: 25,
    damageMax: 35,
    description: "整个系统的神经中枢，它的每一次波动都足以改写底层的运行逻辑",
    skills: [
      MonsterSkill(id: "format", name: "全域重构", chance: 0.25, buff: BuffKind.curse, stacks: 3),
      MonsterSkill(id: "reboot", name: "强制归零", chance: 0.3, buff: BuffKind.weak, stacks: 2),
      MonsterSkill(id: "optimize", name: "深度清理", chance: 0.3, buff: BuffKind.vulnerable, stacks: 2),
    ],
  ),
};
