# 弃牌阶段界面更新

## 概述
修改弃牌阶段界面，将原本的网格排列改为横向排列，提升用户体验。

## 主要修改内容

### 1. _discardPhaseView方法修改
- 将GridView.count替换为ListView
- 设置scrollDirection为Axis.horizontal，实现横向滚动
- 添加padding和间距调整，提升界面美观度

### 2. 具体实现
```dart
// 原代码
GridView.count(
  crossAxisCount: 3,
  crossAxisSpacing: 8,
  mainAxisSpacing: 8,
  childAspectRatio: 0.7,
  children: [
    for (int i = 0; i < hand.length; i++)
      _discardPhaseCardView(i, cardDatabase[hand[i]]!),
  ],
)

// 修改后
ListView(
  scrollDirection: Axis.horizontal,
  padding: EdgeInsets.symmetric(horizontal: 16),
  children: [
    for (int i = 0; i < hand.length; i++)
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: _discardPhaseCardView(i, cardDatabase[hand[i]]!),
      ),
  ],
)
```

## 运行效果
应用可通过http://localhost:8080访问，弃牌阶段界面显示横向排列的卡牌，玩家可左右滚动查看所有卡牌，点击任意卡牌即可选择保留该牌并完成弃牌。