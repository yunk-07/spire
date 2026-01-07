# 函数使用方法及内部键作用说明

## 1. _cardView 方法
### 使用方法
```dart
Widget _cardView(int index, CardData card)
```
该方法用于创建可拖动的卡牌视图，支持摸牌和弃牌动画效果。

### 内部键作用
- `_cardKeys`: 存储每张卡牌的 GlobalKey，用于获取卡牌位置信息
- `_dealingCards`: 存储正在摸牌的卡牌 ID，用于控制摸牌动画显示
- `_discardingCards`: 存储正在弃牌的卡牌 ID，用于控制弃牌动画显示
- `_cardAnimationControllers`: 存储每张卡牌的动画控制器，用于管理摸牌和弃牌动画的播放

## 2. _randomDrawCards 方法
### 使用方法
```dart
void _randomDrawCards()
```
该方法用于随机抽取卡牌，支持摸牌动画效果。

### 内部键作用
- `_cardAnimationControllers`: 存储每张卡牌的动画控制器，用于启动和停止摸牌动画
- `_dealingCards`: 存储正在摸牌的卡牌 ID，用于控制摸牌动画显示

## 3. endTurn 方法
### 使用方法
```dart
void endTurn()
```
该方法用于结束玩家回合，支持弃牌动画效果。

### 内部键作用
- `_cardAnimationControllers`: 存储每张卡牌的动画控制器，用于启动和停止弃牌动画
- `_discardingCards`: 存储正在弃牌的卡牌 ID，用于控制弃牌动画显示

## 4. dispose 方法
### 使用方法
```dart
@override
void dispose()
```
该方法用于释放所有动画控制器资源，避免内存泄漏。

### 内部键作用
- `_cardAnimationControllers`: 存储每张卡牌的动画控制器，用于遍历释放所有控制器