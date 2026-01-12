// monster_data.dart

/// 系统防护程序分级枚举
enum SystemType { normal, elite, boss }

/// 安全进程数据模型
class SecurityProgram {
  final String id;
  final String name;
  final SystemType type;
  final int maxHp;
  final int baseDamage;
  final String description;
  final List<String> abilities; // 指令集列表
  
  const SecurityProgram({
    required this.id,
    required this.name,
    required this.type,
    required this.maxHp,
    required this.baseDamage,
    required this.description,
    this.abilities = const [],
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
    description: "无处不在的冗余数据流，占用系统带宽",
    abilities: ["增殖", "数据阻塞"],
  ),
  "goblin": SecurityProgram(
    id: "goblin",
    name: "嗅探脚本",
    type: SystemType.normal,
    maxHp: 30,
    baseDamage: 10,
    description: "快速运行的嗅探程序，持续检测接入单元漏洞",
    abilities: ["漏洞探测", "快速扫描"],
  ),
  "skeleton": SecurityProgram(
    id: "skeleton",
    name: "僵尸网络节点",
    type: SystemType.normal,
    maxHp: 25,
    baseDamage: 12,
    description: "被感染的过时系统节点，机械执行拦截指令",
    abilities: ["硬拷贝", "自修复"],
  ),
  "orc_warrior": SecurityProgram(
    id: "orc_warrior",
    name: "系统防火墙",
    type: SystemType.elite,
    maxHp: 60,
    baseDamage: 15,
    description: "高度强化的主动防御系统，拥有极高的拦截效率",
    abilities: ["强制隔离", "深度冲击", "系统通告"],
  ),
  "dark_mage": SecurityProgram(
    id: "dark_mage",
    name: "加密守护进程",
    type: SystemType.elite,
    maxHp: 45,
    baseDamage: 18,
    description: "精通复杂加密算法的后台进程，能够生成防护屏障",
    abilities: ["协议加密", "部署子进程", "资源汲取"],
  ),
  "dragon": SecurityProgram(
    id: "dragon",
    name: "中央控制核心",
    type: SystemType.boss,
    maxHp: 150,
    baseDamage: 25,
    description: "整个系统的最高权限控制中心，拥有毁灭性的清除程序",
    abilities: ["全系统清除", "权限威慑", "动态加密层", "递归锁定"],
  ),
};