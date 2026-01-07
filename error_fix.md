# 空值检查异常修复

## 问题描述
应用运行时出现 `_TypeError (Null check operator used on a null value)` 异常，错误发生在第2357行：`animation: _cardAnimationControllers[card.id]!`。

## 原因分析
当 `_dealingCards` 或 `_discardingCards` 包含某张卡牌ID，但 `_cardAnimationControllers` 中没有对应的动画控制器时，使用 `!` 空值检查运算符会导致异常。

## 修复方案
在 `AnimatedBuilder` 组件的条件判断中添加 `_cardAnimationControllers.containsKey(card.id)` 检查，确保只有当动画控制器存在时才渲染动画组件。

## 具体修改

### 摸牌扫描带动画
```dart
// 原代码
if (_dealingCards.contains(card.id))
  AnimatedBuilder(
    animation: _cardAnimationControllers[card.id]!,
    ...
  )

// 修改后
if (_dealingCards.contains(card.id) && _cardAnimationControllers.containsKey(card.id))
  AnimatedBuilder(
    animation: _cardAnimationControllers[card.id]!,
    ...
  )
```

### 弃牌扫描带动画
```dart
// 原代码
if (_discardingCards.contains(card.id))
  AnimatedBuilder(
    animation: _cardAnimationControllers[card.id]!,
    ...
  )

// 修改后
if (_discardingCards.contains(card.id) && _cardAnimationControllers.containsKey(card.id))
  AnimatedBuilder(
    animation: _cardAnimationControllers[card.id]!,
    ...
  )
```

## 运行效果
应用可通过http://localhost:8080访问，摸牌和弃牌阶段的扫描带动画正常显示，不再出现空值检查异常。