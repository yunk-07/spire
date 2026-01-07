// monster_data.dart

/// 怪物类型枚举
enum MonsterType { normal, elite, boss }

/// 怪物数据模型
class MonsterData {
  final String id;
  final String name;
  final MonsterType type;
  final int maxHp;
  final int baseDamage;
  final String description;
  final List<String> abilities; // 怪物技能列表
  
  const MonsterData({
    required this.id,
    required this.name,
    required this.type,
    required this.maxHp,
    required this.baseDamage,
    required this.description,
    this.abilities = const [],
  });
}

/// 怪物数据库
const Map<String, MonsterData> monsterDatabase = {
  "slime": MonsterData(
    id: "slime",
    name: "史莱姆",
    type: MonsterType.normal,
    maxHp: 40,
    baseDamage: 8,
    description: "黏糊糊的史莱姆，行动缓慢但生命力顽强",
    abilities: ["分裂", "粘液攻击"],
  ),
  "goblin": MonsterData(
    id: "goblin",
    name: "哥布林",
    type: MonsterType.normal,
    maxHp: 30,
    baseDamage: 10,
    description: "狡猾的哥布林，擅长偷袭和快速攻击",
    abilities: ["偷袭", "逃跑"],
  ),
  "skeleton": MonsterData(
    id: "skeleton",
    name: "骷髅",
    type: MonsterType.normal,
    maxHp: 25,
    baseDamage: 12,
    description: "不死的骷髅战士，对物理攻击有抗性",
    abilities: ["骨甲", "复活"],
  ),
  "orc_warrior": MonsterData(
    id: "orc_warrior",
    name: "兽人战士",
    type: MonsterType.elite,
    maxHp: 60,
    baseDamage: 15,
    description: "强大的兽人战士，拥有狂暴的力量",
    abilities: ["狂暴", "重击", "战吼"],
  ),
  "dark_mage": MonsterData(
    id: "dark_mage",
    name: "黑暗法师",
    type: MonsterType.elite,
    maxHp: 45,
    baseDamage: 18,
    description: "精通黑暗魔法的法师，能够召唤亡灵",
    abilities: ["暗影箭", "召唤骷髅", "生命吸取"],
  ),
  "dragon": MonsterData(
    id: "dragon",
    name: "巨龙",
    type: MonsterType.boss,
    maxHp: 150,
    baseDamage: 25,
    description: "传说中的巨龙，拥有毁灭性的火焰吐息",
    abilities: ["火焰吐息", "龙威", "鳞甲防御", "空中俯冲"],
  ),
};