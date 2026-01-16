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
    name: "冗余进程",
    type: SystemType.normal,
    maxHp: 40,
    baseDamage: 8,
    damageMin: 6,
    damageMax: 10,
    description: "无处不在的冗余数据流，占用系统带宽",
    skills: [
      MonsterSkill(id: "jam", name: "数据阻塞", chance: 0.3, buff: BuffKind.vulnerable, stacks: 1),
    ],
  ),
  "goblin": SecurityProgram(
    id: "goblin",
    name: "嗅探脚本",
    type: SystemType.normal,
    maxHp: 30,
    baseDamage: 10,
    damageMin: 8,
    damageMax: 12,
    description: "快速运行的嗅探程序，持续检测接入单元漏洞",
    skills: [
      MonsterSkill(id: "probe", name: "漏洞探测", chance: 0.35, buff: BuffKind.vulnerable, stacks: 1),
      MonsterSkill(id: "strain", name: "快速扫描", chance: 0.25, buff: BuffKind.weak, stacks: 1),
    ],
  ),
  "skeleton": SecurityProgram(
    id: "skeleton",
    name: "僵尸网络节点",
    type: SystemType.normal,
    maxHp: 25,
    baseDamage: 12,
    damageMin: 10,
    damageMax: 14,
    description: "被感染的过时系统节点，机械执行拦截指令",
    skills: [
      MonsterSkill(id: "infect", name: "硬拷贝", chance: 0.25, buff: BuffKind.curse, stacks: 1),
    ],
  ),
  "orc_warrior": SecurityProgram(
    id: "orc_warrior",
    name: "系统防火墙",
    type: SystemType.elite,
    maxHp: 60,
    baseDamage: 15,
    damageMin: 13,
    damageMax: 18,
    description: "高度强化的主动防御系统，拥有极高的拦截效率",
    skills: [
      MonsterSkill(id: "isolate", name: "强制隔离", chance: 0.35, buff: BuffKind.weak, stacks: 2),
      MonsterSkill(id: "blast", name: "深度冲击", chance: 0.25),
    ],
  ),
  "dark_mage": SecurityProgram(
    id: "dark_mage",
    name: "加密守护进程",
    type: SystemType.elite,
    maxHp: 45,
    baseDamage: 18,
    damageMin: 16,
    damageMax: 20,
    description: "精通复杂加密算法的后台进程，能够生成防护屏障",
    skills: [
      MonsterSkill(id: "drain", name: "资源汲取", chance: 0.3, buff: BuffKind.curse, stacks: 2),
    ],
  ),
  "dragon": SecurityProgram(
    id: "dragon",
    name: "中央控制核心",
    type: SystemType.boss,
    maxHp: 150,
    baseDamage: 25,
    damageMin: 22,
    damageMax: 30,
    description: "整个系统的最高权限控制中心，拥有毁灭性的清除程序",
    skills: [
      MonsterSkill(id: "lock", name: "递归锁定", chance: 0.4, buff: BuffKind.curse, stacks: 2),
      MonsterSkill(id: "pressure", name: "权限威慑", chance: 0.3, buff: BuffKind.weak, stacks: 2),
      MonsterSkill(id: "expose", name: "动态加密层", chance: 0.3, buff: BuffKind.vulnerable, stacks: 2),
    ],
  ),
};
