class BrainChip {
  final String id;
  final String name;
  final int level;
  final String? effect; // 使用 DSL 描述效果，例如 'strength 2'
  final int themeColor; // ARGB hex color
  final String description;
  const BrainChip({
    required this.id,
    required this.name,
    required this.level,
    this.effect,
    required this.themeColor,
    required this.description,
  });
}

const List<BrainChip> brainChipPool = [
  BrainChip(
    id: "accel_1_0",
    name: "加速运算脑机1.0",
    level: 1,
    effect: "strength 2",
    themeColor: 0xFF00FFCC,
    description: "在开局时直接提升 2 点算力，加速所有指令执行。",
  ),
  BrainChip(
    id: "accel_2_0",
    name: "加速运算脑机2.0",
    level: 2,
    effect: "strength 4",
    themeColor: 0xFF00FFCC,
    description: "在开局时直接提升 4 点算力，加速所有指令执行。",
  ),
  BrainChip(
    id: "ann_replacement",
    name: "ANN接替思维脑机",
    level: 3,
    themeColor: 0xFF9D00FF,
    description: "当手牌小于7，每使用一张牌摸一张牌。",
  ),
];
