# 弃牌阶段扫描带销毁动画实现

## 概述
在弃牌阶段选择保留牌后，为非保留牌添加扫描带销毁动画，替代原有的弃牌动画。

## 主要修改内容

### 1. completeDiscardPhase方法修改
- 移除原有的anim.playCardMotion弃牌动画调用
- 添加扫描带销毁动画控制器管理
- 设置动画持续时间为800ms
- 延迟时间从520ms调整为820ms

### 2. selectCardToKeep方法修改
- 移除原有的anim.playCardMotion弃牌动画调用
- 添加扫描带销毁动画控制器管理
- 设置动画持续时间为800ms
- 延迟时间从520ms调整为820ms

### 3. 回合延迟调整
- 将回合延迟时间从560ms调整为860ms，以匹配新的动画时长

## 技术细节

### 动画实现
```dart
// 创建动画控制器
_cardAnimationControllers[id] = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 800),
);
// 启动动画
_cardAnimationControllers[id]?.forward();

// 延迟后释放控制器
Future.delayed(const Duration(milliseconds: 820), () {
  _discardingCards.remove(id);
  discardPile.add(id);
  hand.remove(id);
  // 释放动画控制器
  _cardAnimationControllers[id]?.dispose();
  _cardAnimationControllers.remove(id);
  setState(() {});
});
```

### UI实现
在_cardView方法中，使用Stack包装Draggable组件，添加AnimatedBuilder实现heightFactor从1到0的渐隐效果，模拟扫描带销毁动画。

## 运行效果
应用可通过http://localhost:8080访问，在弃牌阶段选择保留牌后，非保留牌会显示扫描带销毁动画，动画持续时间为800ms，之后卡牌从手牌中移除并添加到弃牌堆。