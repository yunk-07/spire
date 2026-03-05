// skill_data.dart

enum BuffKind { 
  weak,       // 虚弱：造成的伤害降低 25%
  vulnerable, // 漏洞暴露：受到的伤害增加 50%
  curse,      // 恶意代码/诅咒：受到的伤害额外增加 (层数 * 2)
  sturdy      // 坚固：护盾在回合结束时不会清零，每回合减少 1 层
}

class MonsterSkill {
  final String id;
  final String name;
  final double chance;
  final BuffKind? buff;
  final int stacks;
  final String description;
  const MonsterSkill({
    required this.id,
    required this.name,
    required this.chance,
    this.buff,
    this.stacks = 0,
    this.description = "",
  });
}

/// 全局怪兽技能数据库
const Map<String, MonsterSkill> skillDatabase = {
  // 普通技能
  "jam": MonsterSkill(id: "jam", name: "数据粘附", chance: 0.3, buff: BuffKind.vulnerable, stacks: 1, description: "在目标系统中留下冗余数据碎片，使其漏洞暴露增加 2 层。"),
  "probe": MonsterSkill(id: "probe", name: "漏洞侦察", chance: 0.35, buff: BuffKind.vulnerable, stacks: 2, description: "通过深度扫描寻找系统弱点，施加 2 层漏洞暴露。"),
  "strain": MonsterSkill(id: "strain", name: "指令干扰", chance: 0.25, buff: BuffKind.weak, stacks: 2, description: "发射高频干扰信号，使目标陷入 2 层虚弱状态。"),
  "infect": MonsterSkill(id: "infect", name: "代码侵蚀", chance: 0.25, buff: BuffKind.curse, stacks: 1, description: "注入自我复制的恶意代码，施加 2 层诅咒。"),
  "repeat": MonsterSkill(id: "repeat", name: "指令重放", chance: 0.3, buff: BuffKind.weak, stacks: 2, description: "强制系统重复执行无效指令，造成 2 层虚弱。"),
  "shock": MonsterSkill(id: "shock", name: "高压脉冲", chance: 0.4, buff: BuffKind.vulnerable, stacks: 1, description: "瞬间释放高压电流，导致系统 1 层漏洞暴露。"),
  "heavy_slam": MonsterSkill(id: "heavy_slam", name: "重力冲击", chance: 0.2, buff: BuffKind.weak, stacks: 2, description: "利用质量优势进行猛烈撞击，造成 2 层虚弱。"),
  "siphon": MonsterSkill(id: "siphon", name: "算力吸取", chance: 0.3, buff: BuffKind.weak, stacks: 2, description: "从目标连接中窃取计算资源，施加 2 层虚弱。"),
  "decay": MonsterSkill(id: "decay", name: "逻辑衰变", chance: 0.35, buff: BuffKind.vulnerable, stacks: 2, description: "加速目标数据的熵增过程，施加 2 层漏洞暴露。"),
  
  // 精英技能
  "crush": MonsterSkill(id: "crush", name: "指令碾压", chance: 0.3, buff: BuffKind.vulnerable, stacks: 2, description: "以绝对的算力优势粉碎目标防御，施加 2 层漏洞暴露。"),
  "fortify": MonsterSkill(id: "fortify", name: "系统加固", chance: 0.2, buff: BuffKind.sturdy, stacks: 1, description: "优化自身防御架构，获得 1 层坚固。"),
  "drain": MonsterSkill(id: "drain", name: "能量抽取", chance: 0.3, buff: BuffKind.curse, stacks: 2, description: "强行抽取目标系统能量，施加 2 层诅咒。"),
  "backstab": MonsterSkill(id: "backstab", name: "隐蔽突击", chance: 0.4, buff: BuffKind.vulnerable, stacks: 2, description: "从视觉死角发起突然袭击，施加 2 层漏洞暴露。"),
  "hide": MonsterSkill(id: "hide", name: "掩蔽模式", chance: 0.2, buff: BuffKind.weak, stacks: 1, description: "开启光学迷彩干扰目标视线，造成 1 层虚弱。"),
  "reap": MonsterSkill(id: "reap", name: "逻辑清理", chance: 0.35, buff: BuffKind.curse, stacks: 2, description: "像收割庄稼一样清理异常数据，施加 2 层诅咒。"),
  "curse_lock": MonsterSkill(id: "curse_lock", name: "枷锁诅咒", chance: 0.4, buff: BuffKind.curse, stacks: 1, description: "植入底层锁定协议，施加 1 层诅咒。"),
  "void_crush": MonsterSkill(id: "void_crush", name: "虚空碾压", chance: 0.3, buff: BuffKind.curse, stacks: 2, description: "利用虚空引力坍塌目标数据，施加 2 层诅咒。"),
  "consume": MonsterSkill(id: "consume", name: "吞噬协议", chance: 0.2, buff: BuffKind.sturdy, stacks: 2, description: "吞噬周边冗余数据强化自身，获得 2 层坚固。"),
  
  // Boss 技能
  "lock": MonsterSkill(id: "lock", name: "权限封锁", chance: 0.4, buff: BuffKind.curse, stacks: 2, description: "强行吊销目标的系统操作权限，施加 2 层诅咒。"),
  "pressure": MonsterSkill(id: "pressure", name: "系统压制", chance: 0.3, buff: BuffKind.weak, stacks: 2, description: "释放全域压制场，使目标陷入 2 层虚弱。"),
  "expose": MonsterSkill(id: "expose", name: "弱点标记", chance: 0.3, buff: BuffKind.vulnerable, stacks: 2, description: "在目标核心位置标记永久性漏洞，施加 2 层漏洞暴露。"),
  "format": MonsterSkill(id: "format", name: "全域重构", chance: 0.25, buff: BuffKind.curse, stacks: 3, description: "尝试格式化目标存储区，施加 3 层诅咒。"),
  "reboot": MonsterSkill(id: "reboot", name: "强制归零", chance: 0.3, buff: BuffKind.weak, stacks: 2, description: "强制目标系统重启并丢失部分指令，施加 2 层虚弱。"),
  "optimize": MonsterSkill(id: "optimize", name: "深度清理", chance: 0.3, buff: BuffKind.vulnerable, stacks: 2, description: "对系统进行毁灭性的“优化”清理，施加 2 层漏洞暴露。"),
  "summon": MonsterSkill(id: "summon", name: "呼叫增援", chance: 1.0, buff: null, stacks: 0, description: "调度并部署额外的安保程序接入战斗。"),
  "drought": MonsterSkill(id: "drought", name: "资源枯竭", chance: 0.3, buff: BuffKind.weak, stacks: 3, description: "切断目标的所有能量供给，施加 3 层虚弱。"),
  "famine": MonsterSkill(id: "famine", name: "能量饥荒", chance: 0.3, buff: BuffKind.vulnerable, stacks: 3, description: "引发系统级的大范围能量匮乏，施加 3 层漏洞暴露。"),
  "desolation": MonsterSkill(id: "desolation", name: "最终荒芜", chance: 0.2, buff: BuffKind.curse, stacks: 2, description: "将一切转化为不可读的虚无代码，施加 2 层诅咒。"),
  
  // 其他
  "lockdown": MonsterSkill(id: "lockdown", name: "协议锁定", chance: 0.3, buff: BuffKind.weak, stacks: 1, description: "限制目标的高级指令调用，造成 1 层虚弱。"),
};
